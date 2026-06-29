// WormholeOpfs — the OPFS-from-GitHub backend for w:Wormhole.
//
//  The third backend in the Wormhole plan (see spec/Wormhole_backends_handover.md):
//   the same read_file/write_file/dir contract the worker funnels every I/O through,
//    but rooted in the browser's Origin-Private File System and seeded once from
//     github.com.  This is what lets the app run Story as a medium of the web —
//      open it cold out on the web, the project tree hydrates into OPFS, and Story
//       reads its books / writes its saves with zero local-directory setup.
//
//  Unlike the node backend (scripts/NodeWormholeNav.ts), every API this touches —
//   navigator.storage.getDirectory(), fetch — is a browser API, so this lives in app
//    code beside WormholeNav, not in the harness.  It is the SAME overlay shape as the
//     node backend: a read-only SEED layer (the github snapshot) under a SCRATCH layer
//      (where writes land); reads check scratch then fall through to seed, dir() merges
//       both with scratch shadowing seed.  Both layers are OPFS subdirectories, so once
//        hydrated the nav has no further network dependency.

export type GithubSource = {
    owner: string
    repo: string
    ref: string             // a branch, tag, or commit-ish
    subpaths?: string[]      // top-level dirs to seed; default ['wormhole','Ghost']
}

// the default tree we carry to make Story work out on the web: the books under
//  wormhole/, plus the top-level Ghost/ source the Lies compile pipeline reads.
const DEFAULT_SUBPATHS = ['wormhole', 'Ghost']

// ── the nav: an overlay over two OPFS directory handles ───────────────────────────
//  read_file / write_file / dir is the entire contract the Wormhole worker uses
//   (Housing.svelte.ts → Wormhole / rw_op).  Seed is read-only; scratch takes writes.
export class OpfsOverlayNav {
    seed: FileSystemDirectoryHandle      // the github snapshot — read-only
    scratch: FileSystemDirectoryHandle   // this origin's writes
    is_opfs_github = true                // the DirectoryOpener seam recognises this
    label: string

    constructor(seed: FileSystemDirectoryHandle, scratch: FileSystemDirectoryHandle, label = 'opfs') {
        this.seed = seed
        this.scratch = scratch
        this.label = label
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const parts = dir_path.split('/').filter(Boolean)
        for (const root of [this.scratch, this.seed]) {   // scratch shadows seed
            const d = await walk(root, parts, false)
            if (!d) continue
            try {
                const fh = await d.getFileHandle(filename)
                return await (await fh.getFile()).text()
            } catch { /* not in this layer — fall through */ }
        }
        return null
    }

    // bin_read — read_file's binary twin: returns the raw bytes (no .text()), for audio etc.  Scratch
    //  shadows seed, same as read_file.  The rw_op 'bin' handler parks this on req.c (off-snap, never snapped).
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const parts = dir_path.split('/').filter(Boolean)
        for (const root of [this.scratch, this.seed]) {   // scratch shadows seed
            const d = await walk(root, parts, false)
            if (!d) continue
            try {
                const fh = await d.getFileHandle(filename)
                return await (await fh.getFile()).arrayBuffer()
            } catch { /* not in this layer — fall through */ }
        }
        return null
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const parts = dir_path.split('/').filter(Boolean)
        const d = await walk(this.scratch, parts, true)
        const fh = await d!.getFileHandle(filename, { create: true })
        const w = await fh.createWritable()
        await w.write(content)
        await w.close()
    }

    // a DirectoryListing-shaped probe: the worker calls .expand() then reads
    //  .directories / .files (rw_op 'list').  expand() re-reads each call so a
    //   listing taken after a write isn't stale.
    async dir(...parts: string[]): Promise<{ name: string, directories: { name: string }[], files: { name: string }[], expand(): Promise<void> } | null> {
        const present = (await Promise.all([this.seed, this.scratch].map(r => walk(r, parts, false)))).filter(Boolean) as FileSystemDirectoryHandle[]
        if (!present.length) return null
        const listing = {
            name: parts[parts.length - 1] ?? '',
            directories: [] as { name: string }[],
            files: [] as { name: string }[],
            async expand() {
                const seen = new Map<string, boolean>()   // name → isDir; scratch (last) shadows seed
                for (const d of present) {
                    for await (const ent of (d as any).values()) seen.set(ent.name, ent.kind === 'directory')
                }
                listing.directories = [...seen].filter(([, isd]) => isd).map(([name]) => ({ name }))
                listing.files       = [...seen].filter(([, isd]) => !isd).map(([name]) => ({ name }))
            },
        }
        return listing
    }
}

// walk named segments from a directory handle; create missing dirs when asked,
//  else return null on the first absent segment.
async function walk(root: FileSystemDirectoryHandle, parts: string[], create: boolean): Promise<FileSystemDirectoryHandle | null> {
    let here = root
    for (const part of parts) {
        try { here = await here.getDirectoryHandle(part, { create }) }
        catch { return null }
    }
    return here
}

// ── OPFS roots ────────────────────────────────────────────────────────────────────
//  one namespace per (owner,repo) so seeding a second repo never collides; seed and
//   scratch are siblings under it.
function opfs_unavailable(): string | null {
    if (typeof navigator === 'undefined' || !navigator.storage?.getDirectory)
        return 'OPFS unavailable (needs a secure context — https or localhost)'
    return null
}

async function opfs_roots(src: GithubSource): Promise<{ seed: FileSystemDirectoryHandle, scratch: FileSystemDirectoryHandle }> {
    const root = await navigator.storage.getDirectory()
    const ns   = await root.getDirectoryHandle(`wh-${src.owner}-${src.repo}`, { create: true })
    return {
        seed:    await ns.getDirectoryHandle('seed',    { create: true }),
        scratch: await ns.getDirectoryHandle('scratch', { create: true }),
    }
}

const MARKER = '.seed_ref'   // written into the seed root once hydration completes

async function read_marker(seed: FileSystemDirectoryHandle): Promise<string | null> {
    try { return await (await (await seed.getFileHandle(MARKER)).getFile()).text() }
    catch { return null }
}
async function write_marker(seed: FileSystemDirectoryHandle, value: string): Promise<void> {
    const fh = await seed.getFileHandle(MARKER, { create: true })
    const w = await fh.createWritable(); await w.write(value); await w.close()
}

// ── the github hydrator ─────────────────────────────────────────────────────────
//  one Trees API call lists the repo; every matching blob comes from the raw CDN
//   (raw.githubusercontent.com is a CDN, not the 60/hr API — so N blobs cost no
//    API budget).  Idempotent: the marker records what ref filled the seed, so a
//     return visit skips the network entirely unless the ref changed (or force).
type SeedProgress = (done: number, total: number) => void

export async function seed_from_github(
    seed: FileSystemDirectoryHandle,
    src: GithubSource,
    opts: { force?: boolean, onProgress?: SeedProgress } = {},
): Promise<{ seeded: boolean, files: number }> {
    const subpaths = src.subpaths ?? DEFAULT_SUBPATHS
    const want = `${src.ref} :: ${subpaths.join(',')}`
    if (!opts.force && (await read_marker(seed)) === want) return { seeded: false, files: 0 }

    const treeUrl = `https://api.github.com/repos/${src.owner}/${src.repo}/git/trees/${encodeURIComponent(src.ref)}?recursive=1`
    const res = await fetch(treeUrl, { headers: { Accept: 'application/vnd.github+json' } })
    if (!res.ok) throw new Error(`github tree ${res.status} ${res.statusText} for ${treeUrl}`)
    const body = await res.json() as { tree: { path: string, type: string }[], truncated?: boolean }
    if (body.truncated) console.warn('WormholeOpfs: github tree truncated — some files may be missing; seed a narrower subpath set')

    const blobs = body.tree.filter(e => e.type === 'blob' && subpaths.some(s => e.path === s || e.path.startsWith(s + '/')))
    let done = 0
    await pool(blobs, 8, async (e) => {
        const raw = `https://raw.githubusercontent.com/${src.owner}/${src.repo}/${encodeURIComponent(src.ref)}/${e.path.split('/').map(encodeURIComponent).join('/')}`
        const r = await fetch(raw)
        if (!r.ok) throw new Error(`github raw ${r.status} for ${e.path}`)
        const text = await r.text()
        const parts = e.path.split('/')
        const file = parts.pop()!
        const dir = await walk(seed, parts, true)
        const fh = await dir!.getFileHandle(file, { create: true })
        const w = await fh.createWritable(); await w.write(text); await w.close()
        opts.onProgress?.(++done, blobs.length)
    })

    await write_marker(seed, want)
    return { seeded: true, files: blobs.length }
}

// bounded-concurrency map: n workers drain a shared cursor.
async function pool<T>(items: T[], n: number, fn: (item: T, i: number) => Promise<void>): Promise<void> {
    let i = 0
    const worker = async () => { while (i < items.length) { const idx = i++; await fn(items[idx], idx) } }
    await Promise.all(Array.from({ length: Math.min(n, items.length) }, worker))
}

// ── orchestrator: hand back a ready nav, hydrating the seed if needed ─────────────
export async function mount_opfs_github_nav(
    src: GithubSource,
    opts: { force?: boolean, onProgress?: SeedProgress } = {},
): Promise<OpfsOverlayNav> {
    const bad = opfs_unavailable()
    if (bad) throw new Error(bad)
    const { seed, scratch } = await opfs_roots(src)
    await seed_from_github(seed, src, opts)
    return new OpfsOverlayNav(seed, scratch, `${src.owner}/${src.repo}@${src.ref}`)
}

// cheap return-visit probe: was this repo+ref already hydrated into OPFS?  Lets the
//  DirectoryOpener remount the cloud backend with no click and no network.
export async function opfs_github_seeded(src: GithubSource): Promise<boolean> {
    if (opfs_unavailable()) return false
    const subpaths = src.subpaths ?? DEFAULT_SUBPATHS
    const { seed } = await opfs_roots(src)
    return (await read_marker(seed)) === `${src.ref} :: ${subpaths.join(',')}`
}

// the repo this app is served from — the default cloud source.
export const JAMSEND_SOURCE: GithubSource = { owner: 'stylehouse', repo: 'jamsend', ref: 'main' }
