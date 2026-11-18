// gen_store.ts — COMPILED GHOSTS NAMED BY THEIR CONTENT, and the "code moved" fact a push carries.
//
//  WHY (2026-11-18, AtheoryNexus_todo §0.00 step 1).  A tab re-imports a recompiled `.go` by cache-busting its URL
//   (`gen/A/Theory.go?swap=<etag>`, LiesLies Creduler_reswap), found by polling `/__gen/dige` every 2s.  Measured the same day
//    against the dev server: vite caches a module by its WHOLE URL (a repeat of one query ≈10ms, a new query = a fresh svelte
//     compile, 265–550ms) — but a query does not NAME content.  When the file moves, vite invalidates every module of that file,
//      so `?swap=<old>` then serves the NEW bytes under the OLD name.  A name that can lie is not a content name.
//   So the bytes go in a file named by their dige and never rewritten: `src/lib/gen-dige/Theory.<dige>.go`.  A new dige is a
//    new file, so an import of it cannot be stale, needs no busting, and vite never invalidates it (nothing edits it).
//     Every `.go` imports only `$lib/…`, so a copy runs from any directory.
//
//  THE MANIFEST — `{ 'gen/A/Theory.go': dige, 'gen-electrode/M/Heist.go': dige, … }`, one row per build in each FLAVOUR tree.
//   A flavour is just a different file, so it is just a different dige; the trees stay (Electrode, the editor's pinned spine and
//    every writer keep working untouched) and the store is a mirror kept beside them.  The dige is dige.ts's `dig` (sha256 of
//     the text, BOM dropped, 16 hex) — the same value `/__gen/dige` already serves, so a tab's existing map indexes the store.
//      ⚠ `dig` is copied, not imported: editing dige.ts restarts the dev server.  scripts/GenStore.spec.ts pins the two equal.
//
//  WHAT A PUSH CARRIES — `gen_store_sync` returns `moved`: the rows whose dige changed since the last sync (dige '' = gone).
//   That is "code moved" (the `.go`), distinct from "source moved" (the `.g`, a Doc — control:'docindex' already pushes it);
//    §0.00 "Two arrivals, not one".  The watcher wiring and the relay frame live in vite.config (a restart), not here.
//
//  NOTHING IS DELETED BY A SYNC.  A tab that imported dige X keeps X in memory, but a tab booting from an older manifest may
//   still ask for it, so old files stay until `gen_store_gc` drops those outside the manifest and older than a grace period.
import { createHash } from 'node:crypto'
import { mkdirSync, readdirSync, readFileSync, renameSync, statSync, unlinkSync, writeFileSync, existsSync } from 'node:fs'
import { join, resolve } from 'node:path'

export const GEN_FLAVOUR_TREES = ['gen', 'gen-electrode']   // under src/lib — a flavour is `gen-<name>`
export const GEN_STORE_DIR = 'gen-dige'                      // under src/lib — gitignored, derived
const LIB = 'src/lib'

// gen_dig — MUST equal dige.ts `dig` (see header).
export function gen_dig(text: string): string {
    const body = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text
    return createHash('sha256').update(Buffer.from(body, 'utf8')).digest('hex').slice(0, 16)
}

// gen_store_name — where a build lives in the store.  The ghost's own name rides in front so a stack trace still says Theory.
export function gen_store_name(gen_rel: string, dige: string): string {
    const base = gen_rel.split('/').pop()!.replace(/\.go$/, '')
    return `${GEN_STORE_DIR}/${base}.${dige}.go`
}

type Memo = { mtime: number, size: number, dige: string }
export type GenStore = { manifest: Record<string, string>, memo: Map<string, Memo> }
export const gen_store_new = (): GenStore => ({ manifest: {}, memo: new Map() })

function walk(lib_abs: string, rel: string, out: string[]) {
    let entries: any[]
    try { entries = readdirSync(join(lib_abs, rel), { withFileTypes: true }) as any } catch { return }
    for (const e of entries) {
        if (e.name.startsWith('.')) continue
        const child = `${rel}/${e.name}`
        if (e.isDirectory()) walk(lib_abs, child, out)
        else if (e.isFile() && e.name.endsWith('.go')) out.push(child)
    }
}

// gen_store_put — one build into the store, if its dige is not there yet.  Written to a dot-tmp and renamed, so a tab never
//  imports half a file.  Returns the dige.
export function gen_store_put(repo_root: string, gen_rel: string, text?: string): string {
    const lib = join(resolve(repo_root), LIB)
    if (text == null) text = readFileSync(join(lib, gen_rel), 'utf8')
    const dige = gen_dig(text)
    const dest = join(lib, gen_store_name(gen_rel, dige))
    if (!existsSync(dest)) {
        mkdirSync(join(lib, GEN_STORE_DIR), { recursive: true })
        const tmp = join(lib, GEN_STORE_DIR, `.${dige}.${process.pid}.tmp`)
        writeFileSync(tmp, text, 'utf8')
        renameSync(tmp, dest)
    }
    return dige
}

// gen_store_sync — walk every flavour tree, store what is new, and say what moved since the last sync.  A stat sweep; a file
//  is read only when its mtime|size changed.  The first sync (empty manifest) reports everything as moved — a caller pushing
//   `moved` should skip the boot sync (nobody holds an older manifest from THIS process).
export function gen_store_sync(repo_root: string, st: GenStore): { manifest: Record<string, string>, moved: { gen: string, dige: string }[] } {
    const lib = join(resolve(repo_root), LIB)
    const gens: string[] = []
    for (const t of GEN_FLAVOUR_TREES) walk(lib, t, gens)
    const next: Record<string, string> = {}
    for (const g of gens) {
        let s
        try { s = statSync(join(lib, g)) } catch { continue }
        const mtime = Math.floor(s.mtimeMs), size = s.size
        const had = st.memo.get(g)
        if (had && had.mtime === mtime && had.size === size) { next[g] = had.dige; continue }
        let text: string
        try { text = readFileSync(join(lib, g), 'utf8') } catch { continue }
        const dige = gen_store_put(repo_root, g, text)
        st.memo.set(g, { mtime, size, dige })
        next[g] = dige
    }
    const moved: { gen: string, dige: string }[] = []
    for (const g of Object.keys(next).sort()) if (st.manifest[g] !== next[g]) moved.push({ gen: g, dige: next[g] })
    for (const g of Object.keys(st.manifest)) if (!(g in next)) { moved.push({ gen: g, dige: '' }); st.memo.delete(g) }
    st.manifest = next
    return { manifest: next, moved }
}

// gen_store_gc — drop stored builds outside the manifest and older than `grace_ms`.  Returns how many went.
export function gen_store_gc(repo_root: string, manifest: Record<string, string>, grace_ms = 24 * 3600_000, now = Date.now()): number {
    const dir = join(resolve(repo_root), LIB, GEN_STORE_DIR)
    const live = new Set(Object.entries(manifest).map(([g, d]) => gen_store_name(g, d).slice(GEN_STORE_DIR.length + 1)))
    let names: string[]
    try { names = readdirSync(dir) } catch { return 0 }
    let n = 0
    for (const f of names) {
        if (live.has(f)) continue
        const abs = join(dir, f)
        try { if (now - statSync(abs).mtimeMs < grace_ms) continue; unlinkSync(abs); n++ } catch { /* raced */ }
    }
    return n
}
