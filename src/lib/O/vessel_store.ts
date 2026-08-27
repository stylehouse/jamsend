// vessel_store.ts — the body-local Dexie the Division keeps OFF the wire (Division_todo §STORAGE):
//  two durable facts a machine holds about a soul that must NEVER replicate, so they cannot live on
//   the %Peering tree the account export carries.
//   · BodyKey — a body's own durable keypair, one per (store × soul).  Minted the first time a soul
//      stands up in this store; the stable identity that keys the Charter roster and the thing the
//       LinkDevice ceremony encrypts the account TO.  Body-local: the SAME soul on another machine
//        holds a DIFFERENT body key.  Losing it = this body forgets which roster row is itself, no
//         worse (a fresh key mints a fresh row; the Seat re-charters).
//   · Vessel — one running instance's census row (a tab, the daemon process).  Keyed by the
//      per-instance token; grouped by root_prepub it yields that soul's local SUBNET (the vessels
//       serving it here, now).  Pure runtime census — it is the machine's live truth, never soul-truth.
//
// ITS OWN DATABASE, the census_store precedent: not Housing's `House` table (whose $effect
//  re-stringifies the whole stashed blob on every nested change), own schema, own version line, own
//   cadence.  A plain .ts (no `<script module>`) so it has no HMR boundary — the tax lands only when
//    THIS file changes, ~never.
//
// EVERY call is best-effort.  A blocked or absent IndexedDB (a private window, the daemon's jsdom, a
//  Story boot, a quota refusal) must cost the caller nothing: the guarded path returns the safe empty
//   answer and the body simply behaves as it did before any of this existed (mint a fresh key, run
//    solo, no census).  No call here ever throws into a ghost.
import { Dexie, type EntityTable } from 'dexie'

export interface BodyKeyRow {
    /** PK: the soul's prepub — one body key per soul per store. */
    root_prepub: string
    /** the body key's own full pub / secret / derived prepub (its identity in the Charter roster). */
    pub: string
    key: string
    prepub: string
    at: number
}

export interface VesselRow {
    /** PK: the per-instance token (Swarm_cohort_vessel) — each tab / process its own place. */
    vessel: string
    /** the soul this vessel serves — the subnet key a root prepub groups by. */
    root_prepub: string
    /** the session address this vessel holds (<prepub> bare, or <prepub>_N). */
    address: string
    /** the FSA mount handle id this vessel holds, or '' (a vessel may differ in its mount). */
    fsa: string
    /** last heartbeat, ms — the sweep prunes rows older than a threshold (dead tabs). */
    alive: number
}

// `indexedDB` is absent in the daemon's jsdom and in a Story boot; touching Dexie there throws at
//  open.  Gate on it once so every function below is a clean no-op off-browser.
const HAS_IDB = typeof indexedDB !== 'undefined'

export const db = new Dexie('vessel') as Dexie & {
    BodyKey: EntityTable<BodyKeyRow, 'root_prepub'>
    Vessel: EntityTable<VesselRow, 'vessel'>
}
db.version(1).stores({
    BodyKey: 'root_prepub',
    Vessel: 'vessel, root_prepub',
})

// ── the body key ─────────────────────────────────────────────────────────────────────────────

/** Read this store's durable body key for `root_prepub`, or undefined (first stand-up / no IDB). */
export async function bodykey_read(root_prepub: string): Promise<BodyKeyRow | undefined> {
    if (!HAS_IDB) return undefined
    try { return await db.BodyKey.get(root_prepub) } catch { return undefined }
}

/** Persist a freshly-minted body key.  Idempotent by root_prepub — a second stand-up reads first. */
export async function bodykey_write(row: BodyKeyRow): Promise<void> {
    if (!HAS_IDB) return
    try { await db.BodyKey.put(row) } catch { /* body runs keyless-durable, mints fresh next boot */ }
}

// ── the vessel census ────────────────────────────────────────────────────────────────────────

/** Register / refresh this running instance's row (called at stand + on each heartbeat). */
export async function vessel_register(row: VesselRow): Promise<void> {
    if (!HAS_IDB) return
    try { await db.Vessel.put(row) } catch { /* solo, uncensused — today's behaviour */ }
}

/** The soul's local SUBNET: every vessel row serving `root_prepub` in this store, address-ascending
 *  (the bare-first order Swarm_body_pick relies on).  Empty when off-browser or none registered. */
export async function vessel_subnet(root_prepub: string): Promise<VesselRow[]> {
    if (!HAS_IDB) return []
    try {
        const rows = await db.Vessel.where('root_prepub').equals(root_prepub).toArray()
        return rows.sort((a, b) => (a.address < b.address ? -1 : a.address > b.address ? 1 : 0))
    } catch { return [] }
}

/** Drop this instance's row (a clean tab close; the sweep catches the unclean ones). */
export async function vessel_drop(vessel: string): Promise<void> {
    if (!HAS_IDB) return
    try { await db.Vessel.delete(vessel) } catch { /* the sweep reaps it by `alive` */ }
}

/** Prune vessel rows not seen since `before` (ms) — dead tabs that never dropped their row. */
export async function vessel_sweep(before: number): Promise<void> {
    if (!HAS_IDB) return
    try { await db.Vessel.where('alive').below(before).delete() } catch { /* best-effort hygiene */ }
}
