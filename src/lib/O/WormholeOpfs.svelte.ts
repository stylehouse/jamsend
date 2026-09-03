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

    // read_range — bin_read's SEEKABLE twin: bytes [offset, offset+len) only, never the whole file
    //  (a 1.4GB asset must not slurp).  File.slice over the OPFS file handle reads just the window;
    //   len omitted ⇒ to EOF.  Returns the window + the file's total size so a consumer can seek.
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const parts = dir_path.split('/').filter(Boolean)
        for (const root of [this.scratch, this.seed]) {   // scratch shadows seed
            const d = await walk(root, parts, false)
            if (!d) continue
            try {
                const file = await (await d.getFileHandle(filename)).getFile()
                const end = len == null ? file.size : Math.min(file.size, offset + len)
                return { buffer: await file.slice(offset, end).arrayBuffer(), size: file.size }
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

    // bin_write — write_file's BINARY twin: the SAME scratch-layer write, but raw bytes (createWritable
    //  takes a BufferSource directly, no TextEncoder).  Completes the contract so all THREE backends
    //   (FSA WormholeNav, remote RemoteWormholeNav, this cloud overlay) can write binary — no backend is a
    //    partial nav that surfaces "can't write binary" three layers away for a WAV-writing Book.
    // bin_rm — bin_read's deleting twin (SoundPooling "off" + the steward's evict take the bytes with the
    //  card).  Writes land in scratch, so that is the layer a delete reaches; a name that is not there
    //   answers false (a sweep is not an error), anything else throws as it would on read.
    async bin_rm(dir_path: string, filename: string): Promise<boolean> {
        const parts = dir_path.split('/').filter(Boolean)
        const d = await walk(this.scratch, parts, false)
        if (!d) return false
        try { await d.removeEntry(filename); return true }
        catch (e: any) { if (e && e.name === 'NotFoundError') return false; throw e }
    }

    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const parts = dir_path.split('/').filter(Boolean)
        const d = await walk(this.scratch, parts, true)
        const fh = await d!.getFileHandle(filename, { create: true })
        const w = await fh.createWritable()
        await w.write(bytes as BufferSource)
        await w.close()
    }

    // bin_append — bin_write's STREAMING twin (the FSA WormholeNav.bin_append shape, over OPFS): extend a
    //  file at its END without holding the whole thing in memory.  createWritable({keepExistingData}) keeps
    //   the bytes already on disk and a positioned write lands the chunk at the current size, so a heist can
    //    stream a big asset chunk-at-a-time (Radio_todo §10.2 #1) rather than assembling one Uint8Array(size).
    //     Writes ALWAYS land in scratch, same layer as bin_write; the current size is read off the scratch
    //      file handle (0 when it does not exist yet — the FIRST append creates it, so a caller can append
    //       from seq 0 with no separate create).  OPFS getFileHandle is scoped to scratch here (not the seed
    //        overlay): an append extends this origin's own write, never the read-only github snapshot.
    async bin_append(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const parts = dir_path.split('/').filter(Boolean)
        const d = await walk(this.scratch, parts, true)
        const fh = await d!.getFileHandle(filename, { create: true })
        // current size off the scratch handle: fresh (0-byte) file ⇒ 0, so the first append is the create.
        const size = (await fh.getFile()).size
        const w = await fh.createWritable({ keepExistingData: true })   // don't truncate — extend
        await w.write({ type: 'write', position: size, data: bytes as BufferSource })
        await w.close()
    }

    // bin_writer — bin_append's HELD twin (the WormholeNav.bin_writer shape, over OPFS).  Same reason:
    //  createWritable copies the existing file into a `.crswap` on EVERY open, so a per-chunk append pays
    //   a full-file copy per chunk (N²/2 total).  Hold ONE writer for the whole landing instead — the swap
    //    starts empty (keepExistingData omitted ⇒ we stream from seq 0), N positioned writes, one close.
    //     Writes land in scratch, same layer as bin_write|bin_append.
    //  `write(bytes, at?)`: `at` names the offset explicitly (the wire session uses it so a re-emitted chunk
    //   rewrites rather than duplicates); omitted, it appends at the writer's own running position.
    async bin_writer(dir_path: string, filename: string): Promise<{ write(bytes: Uint8Array | ArrayBuffer, at?: number): Promise<void>, close(): Promise<void>, abort(): Promise<void> }> {
        const parts = dir_path.split('/').filter(Boolean)
        const d = await walk(this.scratch, parts, true)
        const fh = await d!.getFileHandle(filename, { create: true })
        const w = await fh.createWritable()
        let position = 0
        let done = false
        return {
            async write(bytes: Uint8Array | ArrayBuffer, at?: number) {
                if (done) throw new Error('bin_writer: write after close')
                const b = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes)
                const pos = at == null ? position : at
                await w.write({ type: 'write', position: pos, data: b as BufferSource })
                position = pos + b.byteLength
            },
            async close() { if (done) return; done = true; await w.close() },
            async abort() { if (done) return; done = true; await w.abort().catch(() => {}) },
        }
    }

    // dir_at — dir() from a single '/'-joined path string (the discovery-site convenience).
    async dir_at(path: string) { return this.dir(...path.split('/').filter(Boolean)) }
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
    // ⚠ THIS MARKER IS REF-KEYED, AND THE REF IN USE IS `main` — a moving target, so this key never
    //  changes as main advances and a browser profile that seeded once NEVER re-seeds.  New Books
    //   added after someone's first visit are invisible to them, silently and permanently.
    //  `LazyGithubNav.manifest` resolves the ref to a commit sha to close exactly this (see
    //   `head_sha` there).  Left alone here deliberately — this is the no-share cloud path, it is
    //    hundreds of blobs, and re-seeding it on every push is a different (and worse) trade than
    //     re-indexing a manifest.  It wants an incremental update keyed on the sha, not a flag flip.
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

// ── OpfsPlainNav — the SoundPool's nav: plain OPFS, no github seed (Portability_todo §3) ──────────
//  The pool is scratch all the way down — a LOFI cache pressed from Originals, expendable by design —
//   so the overlay's read-only seed layer has nothing to hold.  Rather than a fourth nav
//    implementation, this IS the overlay with both layers pointed at the ONE directory: every
//     read/write/dir method behaves identically (scratch-shadows-seed collapses to a probe of the
//      same handle), and the nav keeps FULL parity (bin_append/bin_writer/read_range), so MountNav's
//       capability narrowing never degrades the share when the pool mounts beside it.
export class OpfsPlainNav extends OpfsOverlayNav {
    is_opfs_github = false   // NOT the cloud backend — the DirectoryOpener seam must not read it as one
    is_opfs_pool = true
    constructor(root: FileSystemDirectoryHandle, label = 'pool') { super(root, root, label) }
}

// mount_opfs_pool_nav — stand the pool nav on the OPFS directory `<name>/` under this origin's root.
//  FEATURE-GUARDED, not throwing: no OPFS (jsdom, the daemon, an insecure context) answers null and
//   the caller mounts nothing — a `path:"pool/…"` is then a dead reference that starts resolving the
//    day a pool mount stands, exactly the behaviour `"music/…"` has before a share opens.
export async function mount_opfs_pool_nav(name = 'pool'): Promise<OpfsPlainNav | null> {
    if (opfs_unavailable()) return null
    const root = await navigator.storage.getDirectory()
    return new OpfsPlainNav(await root.getDirectoryHandle(name, { create: true }), name)
}

// ── LazyGithubNav — the app's own tree, fetched a file at a time ─────────────────
//
//  The owner, 2026-08-12: *"just the Sounditron toc.snap needs downloading initially, each step may
//   only download if it wants diffing."*
//
//  `seed_from_github` above hydrates the WHOLE subpath set up front — hundreds of blobs before the
//   first read. That is right for the no-share cloud demo (it is going to read most of it), and
//    wrong for a listener who granted their music folder and needs the app tree MOUNTED under it:
//     there, the app reads one `toc.snap` to start, and an `NNN.snap` only when a step actually
//      wants to diff against it. Most of the tree is never touched at all.
//
//  So: **one index, N lazy blobs.** A single git Trees call lists the repo (that is 1 request
//   against the 60/hr API budget, not N), and it is persisted, so a return visit costs nothing. Path
//    LISTING is answered entirely from that manifest — `dir()` never touches the network, which is
//     what keeps a Story walk cheap. Only an actual `read_file`/`bin_read` of a path materialises
//      that one blob, from the raw CDN (not the API), into the OPFS seed where it stays.
//
//  Writes go to the OPFS scratch layer through the same `OpfsOverlayNav` that backs the eager
//   version, so scratch shadows seed exactly as before and a written file is never re-fetched.
//  Blobs are stored as BYTES (`arrayBuffer`), not `.text()` as the eager seeder does — text is
//   lossy for anything binary, and this path is reachable for any file in the tree.
export class LazyGithubNav {
    opfs: OpfsOverlayNav
    src: GithubSource
    seed: FileSystemDirectoryHandle
    is_opfs_github = true          // the DirectoryOpener seam recognises this
    is_lazy_github = true          // …and this says listings are free but reads may block
    label: string
    fetched = 0                    // blobs materialised this session — the honest progress number
    _files: Set<string> | null = null
    _inflight = new Map<string, Promise<boolean>>()

    constructor(opfs: OpfsOverlayNav, src: GithubSource, seed: FileSystemDirectoryHandle) {
        this.opfs = opfs
        this.src = src
        this.seed = seed
        this.label = `${src.owner}/${src.repo}@${src.ref} (lazy)`
    }

    // head_sha — what `ref` points at RIGHT NOW.  One cheap API call, and the whole staleness story.
    //
    //  ⚠ WHY THIS EXISTS AT ALL: the obvious cache key is `ref + subpaths`, and it is WRONG, because
    //   the ref in use is `main` — a MOVING target.  Keyed that way the key never changes as main
    //    advances, so a listener who indexed once keeps that manifest for the life of the browser
    //     profile and never sees a Book added after their first visit.  Silent, permanent, and
    //      invisible in testing, because a fresh profile always looks right.  (The eager
    //       `seed_from_github` marker has the same shape — see the note on it below.)
    //  Resolving the ref to a commit sha makes the key CONTENT-ADDRESSED, so it changes exactly when
    //   the tree does.  Steady state is one request per boot; a push costs one more.
    //  FAILS SOFT ON PURPOSE: offline, or rate-limited (this is the 60/hr API, unlike the raw CDN),
    //   returns null and the caller keeps whatever manifest it already had.  A listener who cannot
    //    reach github must still get the Books they indexed yesterday — a freshness check that can
    //     take the tree AWAY is worse than a stale one.
    async head_sha(): Promise<string | null> {
        try {
            const u = `https://api.github.com/repos/${this.src.owner}/${this.src.repo}/commits/${encodeURIComponent(this.src.ref)}`
            const r = await fetch(u, { headers: { Accept: 'application/vnd.github+json' } })
            if (!r.ok) return null
            return (await r.json())?.sha ?? null
        } catch { return null }
    }

    // the manifest: repo-relative blob paths inside the wanted subpaths.  Cached in memory, then in
    //  OPFS keyed by the resolved COMMIT + subpaths (see head_sha above for why not the ref).
    async manifest(): Promise<Set<string>> {
        if (this._files) return this._files
        const subpaths = this.src.subpaths ?? DEFAULT_SUBPATHS
        const at = await this.head_sha()
        const want = `${at ?? this.src.ref} :: ${subpaths.join(',')}`
        try {
            const fh = await this.seed.getFileHandle(TREE_CACHE)
            const cached = JSON.parse(await (await fh.getFile()).text()) as { want: string, paths: string[] }
            // `!at` = we could not ask (offline / rate-limited): take the cache whatever it says.
            if (cached?.paths && (!at || cached.want === want)) { this._files = new Set(cached.paths); return this._files }
        } catch { /* no cache, or unreadable — fall through and re-index */ }

        const treeUrl = `https://api.github.com/repos/${this.src.owner}/${this.src.repo}/git/trees/${encodeURIComponent(this.src.ref)}?recursive=1`
        const res = await fetch(treeUrl, { headers: { Accept: 'application/vnd.github+json' } })
        if (!res.ok) throw new Error(`github tree ${res.status} ${res.statusText} for ${treeUrl}`)
        const body = await res.json() as { tree: { path: string, type: string }[], truncated?: boolean }
        if (body.truncated) console.warn('LazyGithubNav: github tree truncated — seed a narrower subpath set')
        const paths = body.tree
            .filter(e => e.type === 'blob' && subpaths.some(s => e.path === s || e.path.startsWith(s + '/')))
            .map(e => e.path)
        this._files = new Set(paths)
        try {
            const fh = await this.seed.getFileHandle(TREE_CACHE, { create: true })
            const w = await fh.createWritable(); await w.write(JSON.stringify({ want, paths })); await w.close()
        } catch { /* index still usable in memory this session */ }
        return this._files
    }

    // materialise ONE blob into the seed if it is not already there.  Concurrent asks for the same
    //  path share one fetch — a Story step and a probe racing for the same toc.snap must not both pull.
    async _ensure(path: string): Promise<boolean> {
        const parts = path.split('/').filter(Boolean)
        const file = parts.pop()
        if (!file) return false
        // already present in either layer?  scratch first — a local write must never be re-fetched.
        for (const root of [this.opfs.scratch, this.seed]) {
            const d = await walk(root, parts, false)
            if (!d) continue
            try { await d.getFileHandle(file); return true } catch { /* not this layer */ }
        }
        const running = this._inflight.get(path)
        if (running) return running
        const job = (async () => {
            const files = await this.manifest()
            if (!files.has(path)) return false          // not in the tree: an honest miss, no request
            const raw = `https://raw.githubusercontent.com/${this.src.owner}/${this.src.repo}/${encodeURIComponent(this.src.ref)}/${path.split('/').map(encodeURIComponent).join('/')}`
            const r = await fetch(raw)
            if (!r.ok) throw new Error(`github raw ${r.status} for ${path}`)
            const bytes = await r.arrayBuffer()
            const dir = await walk(this.seed, parts, true)
            const fh = await dir!.getFileHandle(file, { create: true })
            const w = await fh.createWritable(); await w.write(bytes); await w.close()
            this.fetched++
            return true
        })().finally(() => { this._inflight.delete(path) })
        this._inflight.set(path, job)
        return job
    }

    _join(dir_path: string, filename: string): string {
        return [...String(dir_path ?? '').split('/').filter(Boolean), filename].join('/')
    }

    // ── the nav surface: ensure the one file, then let the OPFS overlay answer ────────────────────
    async read_file(dir_path: string, filename: string): Promise<string | null> {
        await this._ensure(this._join(dir_path, filename)).catch(() => false)
        return this.opfs.read_file(dir_path, filename)
    }
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        await this._ensure(this._join(dir_path, filename)).catch(() => false)
        return this.opfs.bin_read(dir_path, filename)
    }
    async read_range(dir_path: string, filename: string, offset: number, len?: number) {
        await this._ensure(this._join(dir_path, filename)).catch(() => false)
        return this.opfs.read_range(dir_path, filename, offset, len)
    }

    // writes never consult github — they land in scratch, which shadows the seed from then on
    async write_file(dir_path: string, filename: string, content: string): Promise<void> { return this.opfs.write_file(dir_path, filename, content) }
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> { return this.opfs.bin_write(dir_path, filename, bytes) }
    async bin_rm(dir_path: string, filename: string): Promise<boolean> { return this.opfs.bin_rm ? this.opfs.bin_rm(dir_path, filename) : false }
    async bin_append(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> { return this.opfs.bin_append(dir_path, filename, bytes) }
    async bin_writer(dir_path: string, filename: string) { return this.opfs.bin_writer(dir_path, filename) }

    async dir_at(path: string) { return this.dir(...path.split('/').filter(Boolean)) }

    // LISTING IS FREE — answered from the manifest, merged with whatever scratch has written.  This
    //  is the property that makes lazy viable: a Story walk enumerates the tree without pulling any
    //   of it, and only the files it then READS cost a request.
    async dir(...parts: string[]): Promise<{ name: string, directories: { name: string }[], files: { name: string }[], expand(): Promise<void> } | null> {
        const files = await this.manifest()
        const prefix = parts.length ? parts.join('/') + '/' : ''
        const dirs = new Set<string>()
        const names = new Set<string>()
        let exists = !parts.length
        for (const p of files) {
            if (prefix && !p.startsWith(prefix)) continue
            exists = true
            const rest = p.slice(prefix.length).split('/')
            if (rest.length === 1) names.add(rest[0])
            else dirs.add(rest[0])
        }
        // scratch can hold files github never had (anything this app wrote) — merge them in.
        //  ⚠ `expand()` is REQUIRED: OpfsOverlayNav.dir hands back a listing whose directories/files
        //   are EMPTY until expanded (it re-reads per call so a listing taken after a write is not
        //    stale).  Reading `.files` without it silently merges nothing, and a file this app wrote
        //     goes missing from every listing — caught by scripts/LazyGithubNav.spec.ts.
        const live = await this.opfs.dir(...parts)
        if (live) {
            await live.expand()
            exists = true
            for (const d of live.directories) dirs.add(d.name)
            for (const f of live.files) if (!f.name.startsWith('.')) names.add(f.name)
        }
        if (!exists) return null
        return {
            name: parts.length ? parts[parts.length - 1] : '/',
            directories: [...dirs].sort().map(name => ({ name })),
            files: [...names].filter(n => n !== TREE_CACHE && n !== MARKER).sort().map(name => ({ name })),
            async expand() { /* already whole — the manifest is the listing */ },
        }
    }
}

const TREE_CACHE = '.tree_index.json'   // the persisted git-tree manifest, beside the seed marker

// mount_lazy_github_nav — the lazy twin of mount_opfs_github_nav.  Returns immediately after ONE
//  Trees call; nothing else is fetched until something reads it.
export async function mount_lazy_github_nav(src: GithubSource): Promise<LazyGithubNav> {
    const bad = opfs_unavailable()
    if (bad) throw new Error(bad)
    const { seed, scratch } = await opfs_roots(src)
    const nav = new LazyGithubNav(new OpfsOverlayNav(seed, scratch, `${src.owner}/${src.repo}@${src.ref}`), src, seed)
    await nav.manifest()          // fail loudly here if the repo/ref is wrong, not on the first read
    return nav
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
