<script lang="ts" module>
    // Thangs.svelte — Dexie-backed Thang data ghost.
    //
    // ── what a Thang is ─────────────────────────────────────────────────────────
    //   A Thang is a TheC particle living under some w:Thangs worker:
    //     w/{thang:1, name:'music', stashed:{...}}
    //   The worker's sc.thangs picks the Dexie table:
    //     {w:'Thangs', thangs:'shares'}
    //   liveQuery keeps particles in step with rows; per-thang stashed mutations
    //   are throttle-saved back to the row.
    //
    // ── what to wire ────────────────────────────────────────────────────────────
    //   In Otro/Ghost.svelte, mount this alongside the others:
    //     <Thangs {M} />
    //   In House.may_begin (or any A.* setup):
    //     H.i({A:'Shares'}).i({w:'Thangs', thangs:'shares'})
    //   On the next think pass the ghost subscribes to Dexie; rows arrive,
    //   particles materialise, UI re-derives.
    //
    // ── why no Things.svelte.ts equivalent ──────────────────────────────────────
    //   The TheC universe IS the in-memory collection. SvelteMap<name,Thing>
    //   was duplicate state. ThingsIsms.start() reading allKeys then
    //   spawn_Thing() for each is replaced by liveQuery → particles.
    //   The custom IndexedDBStorage / KVStore / CollectionStorage stack
    //   (open promise sharing, onversionchange, transaction wrappers, etc)
    //   is all things Dexie does already.
    //
    // ── Dexie schema ────────────────────────────────────────────────────────────
    //   One generic table, compound PK [table+name], index on table so
    //   liveQuery can filter cheaply.  New "kinds" of Thang need no schema bump.
    //
    // < a future Thang.start()/stop() lifecycle could come back via concretion:
    //    {thang:1, name:'music', class:'DirectoryShare'} → spawn instance.
    //    Not built here — separate concern from persistence.

    import { Dexie, liveQuery, type EntityTable } from 'dexie'

    interface ThangRow {
        table: string
        name: string
        json: string
    }

    // Module-scope so the connection is shared across <Thangs> instances
    //  (HMR, multiple Otros, whatever) — Dexie handles its own pooling.
    export const db = new Dexie('thangs') as Dexie & {
        Thang: EntityTable<ThangRow, ['table', 'name']>
    }
    db.version(1).stores({
        Thang: '[table+name], table',
    })
</script>

<script lang="ts">
    import { onMount } from 'svelte'
    import { TheC } from "$lib/data/Stuff.svelte"
    import { throttle } from "$lib/Y.svelte"

    let { M } = $props()

    onMount(async () => {
        await M.eatfunc({

//#region w:Thangs
            // -----------------------------------------------------------------
            // w:Thangs  — collection sync between Dexie rows and TheC particles.
            //
            //   First call:  subscribe liveQuery on the named table; on each
            //                emission, post_do() into H.todo so the particle
            //                mutations land inside the beliefs mutex.
            //   Every call:  walk thang particles, throttle-save any whose
            //                JSON has drifted from what we last wrote.
            //
            //   w.sc.thangs is the table name (eg 'shares', 'playlists').
            //   The subscription flag and unsub fn live on w.c (empirical).
            // -----------------------------------------------------------------
            async Thangs(A: TheC, w: TheC, e: TheC) {
                const H = this
                const table = w.sc.thangs as string
                if (!table) {
                    w.oai({ error: 'w:Thangs needs sc.thangs = "<table-name>"' })
                    return
                }

                // First run: open the live subscription
                if (!w.c.thangs_subscribed) {
                    w.c.thangs_subscribed = true

                    const sub = liveQuery(
                        () => db.Thang.where('table').equals(table).toArray()
                    ).subscribe({
                        next: (rows: ThangRow[]) => {
                            // Bounce into H.todo so all particle mutations
                            // run inside the beliefs mutex (no UItime races).
                            H.post_do(async () => {
                                const rowMap = new Map(rows.map(r => [r.name, r]))

                                // drop particles whose row is gone
                                for (const t of w.o({ thang: 1 }) as TheC[]) {
                                    if (!rowMap.has(t.sc.name as string)) {
                                        w.drop(t)
                                    }
                                }

                                // insert/update particles for each row
                                for (const [name, row] of rowMap) {
                                    let stashed: any
                                    try { stashed = JSON.parse(row.json || '{}') }
                                    catch { stashed = {} }

                                    const existing = w.o({ thang: 1, name })[0] as TheC | undefined
                                    if (!existing) {
                                        // fresh particle; mark _last_json so the
                                        // ambient save loop won't immediately re-write
                                        const fresh = w.i({ thang: 1, name, stashed })
                                        fresh.c._last_json = row.json
                                    } else if (existing.c._last_json !== row.json) {
                                        // remote-side change — adopt it
                                        existing.sc.stashed = stashed
                                        existing.c._last_json = row.json
                                        existing.bump_version()
                                    }
                                }
                                H.main()
                            }, { see: `thangs liveQuery ${table}` })
                        },
                        error: (err) => {
                            console.error(`Thangs ${table} liveQuery`, err)
                            w.oai({ error: String(err) })
                        }
                    })
                    // < nothing currently invokes this; House lives as long as Otro
                    w.c.thangs_unsub = () => sub.unsubscribe()
                }

                // Ambient save: any particle whose stashed JSON has drifted
                // gets a throttled put back to Dexie. Each thang owns its own
                // throttle so one chatty thang doesn't starve another.
                for (const t of w.o({ thang: 1 }) as TheC[]) {
                    const json = JSON.stringify(t.sc.stashed ?? {})
                    if (t.c._last_json === json) continue
                    t.c._last_json = json
                    t.c._save ||= throttle(async () => {
                        await db.Thang.put({
                            table,
                            name: t.sc.name as string,
                            json: t.c._last_json as string,
                        })
                    }, 200)
                    t.c._save()
                }

                w.i({ see: `📦 ${table}: ${w.o({ thang: 1 }).length}` })
            },

//#endregion
//#region helpers on H

            // Add a fresh thang. Just writes the row; liveQuery does the rest.
            //  init becomes the new row's stashed. Throws on duplicate name.
            async thang_add(w: TheC, name: string, init: any = {}) {
                const table = w.sc.thangs as string
                if (!table) throw `thang_add: w has no sc.thangs`
                if (!name)  throw `thang_add: !name`
                const existing = await db.Thang.get([table, name])
                if (existing) throw `thang_add: "${name}" already in ${table}`
                await db.Thang.put({
                    table,
                    name,
                    json: JSON.stringify(init),
                })
            },

            // Remove a thang. liveQuery drops the particle on next emission.
            async thang_remove(w: TheC, name: string) {
                const table = w.sc.thangs as string
                if (!table) throw `thang_remove: w has no sc.thangs`
                await db.Thang.delete([table, name])
            },

            // Force-reload one thang's stashed from Dexie.
            //  useful if something outside the particle system wrote the row.
            async thang_reload(w: TheC, name: string) {
                const table = w.sc.thangs as string
                const row = await db.Thang.get([table, name])
                if (!row) return
                const t = w.o({ thang: 1, name })[0] as TheC | undefined
                if (!t) return
                t.sc.stashed = JSON.parse(row.json || '{}')
                t.c._last_json = row.json
                t.bump_version()
            },

            // Read a row's stashed without going through particles —
            //  for ghosts that need the data before liveQuery has fired,
            //  or for one-off probes.
            async thang_peek(table: string, name: string): Promise<any> {
                const row = await db.Thang.get([table, name])
                if (!row) return null
                try { return JSON.parse(row.json || '{}') }
                catch { return {} }
            },

            // Rename: Dexie has no rename, so clone+delete.
            //  The particle.name change comes from liveQuery, not in-place.
            async thang_rename(w: TheC, from: string, to: string) {
                const table = w.sc.thangs as string
                if (!table) throw `thang_rename: w has no sc.thangs`
                if (from === to) return
                const row = await db.Thang.get([table, from])
                if (!row) throw `thang_rename: "${from}" not found in ${table}`
                const clash = await db.Thang.get([table, to])
                if (clash) throw `thang_rename: "${to}" already exists in ${table}`
                await db.transaction('rw', db.Thang, async () => {
                    await db.Thang.put({ table, name: to, json: row.json })
                    await db.Thang.delete([table, from])
                })
            },

//#endregion
        })
    })
</script>
