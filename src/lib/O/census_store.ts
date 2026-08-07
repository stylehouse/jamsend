// census_store.ts — the one Dexie table the meander census lives in.  Split out of Census.svelte
//  purely so that component needs no `<script module>` block: a module block makes a component
//   refuse HMR, and a full page reload is not free here — the human's player tabs die with it
//    (spec: "a `<script module>` block kills HMR").  A plain .ts has no HMR boundary either way,
//     so the tax lands only when THIS file changes, which is approximately never.
//
// ITS OWN DATABASE, not Housing's `House` table (whose $effect re-stringifies the whole stashed
//  blob on every nested change at a 200 ms throttle — measured 1 MiB / 7 ms for this map, five
//   times a second on the main thread).  Own schema, own cadence, own version line.
import { Dexie, type EntityTable } from 'dexie'

export interface CensusRow {
    /** the row key.  ONE row: the census keys are already absolute (`base + '/' + rel`), so several
     *  share bases live in one forest exactly as they do on `.c`. */
    k: string
    /** census_codec's preorder tree text. */
    txt: string
    at: number
    n: number
}

export const db = new Dexie('census') as Dexie & { Census: EntityTable<CensusRow, 'k'> }
db.version(1).stores({ Census: 'k' })

export const CENSUS_KEY = 'meander'

/** Every call is best-effort: a blocked or absent IndexedDB (a private window, a quota refusal, a
 *  first-run schema upgrade) must cost the page nothing — the wander then simply starts cold,
 *   which is exactly the behaviour that shipped before any of this existed. */
export async function census_read(): Promise<CensusRow | undefined> {
    return await db.Census.get(CENSUS_KEY)
}

export async function census_write(txt: string, n: number): Promise<void> {
    await db.Census.put({ k: CENSUS_KEY, txt, at: Date.now(), n })
}

export async function census_drop(): Promise<void> {
    await db.Census.delete(CENSUS_KEY)
}
