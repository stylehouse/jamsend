// OriginNav — the app's own tree (wormhole/, Ghost/), read-only, from the server that served this page.
//
//  The other half of src/lib/server/wormhole_serve.ts — read its header for WHY.  In one line: a page
//   with no repo folder used to read its Books and Grounds from github `main`, which lags the code by
//    however long a commit sits unpushed; now it reads them from the same server as its JavaScript.
//
//  THE SURFACE IS LazyGithubNav's (WormholeOpfs.svelte.ts), so it drops into the same two seams
//   (AppTreeNav's lower layer; the no-share cloud mount) and nothing above it learns which it got:
//    listing is free (answered from ONE manifest), a read costs one request, and two callers racing
//     for the same file share it.
//  WHAT DIFFERS, on purpose:
//   · NO OPFS SEED.  LazyGithubNav materialises each blob into OPFS and never re-checks it — fine for
//      a commit-pinned mirror, wrong for a live tree (the stale-forever class all over again).  Here a
//       read is cached in memory keyed by the manifest's STAMP (`<mtime>-<size>`), so an edited file is
//        refetched exactly when the server says it moved.  The server is the one that served the page:
//         a round trip to it is the cheapest network there is.
//   · THE MANIFEST REFRESHES — a conditional GET (304 when nothing moved) at most every REFRESH_MS, so
//      a Book or Ground added on the server shows up without a reload.
//   · `build` — the server's build id rides every manifest.  If it changes under a living tab, this
//      tab's CODE is older than the server's DATA (version skew); `build_moved` latches and a warning
//       says so once.  What to do about it (reload?) is the production server's policy, not decided
//        here — in dev vite reloads every tab on a restart anyway.
//   · WRITES: none of its own.  An optional `scratch` nav takes them and shadows reads (the no-share
//      cloud mount's shape); without one, writes are refused loudly — AppTreeNav never sends any.

type Listing = { name: string, directories: { name: string }[], files: { name: string }[], expanded: boolean, expand(): Promise<void> }
type Scratch = { read_file?: any, bin_read?: any, write_file?: any, bin_write?: any, bin_append?: any, bin_writer?: any, bin_rm?: any, dir?: any }

const REFRESH_MS = 3000

export class OriginNav {
    is_origin = true               // the seam a diagnostic recognises, beside is_opfs_github / is_remote
    is_lazy_github = false
    label: string
    base: string                   // '' = this page's own origin
    build: string | null = null    // the build the FIRST manifest named — this tab's code is that build's
    build_moved: string | null = null
    fetched = 0                    // file bodies pulled this session — the honest progress number
    scratch: Scratch | null

    _files: Record<string, string> | null = null
    _etag: string | null = null
    _at = 0
    _refreshing: Promise<Record<string, string>> | null = null
    _cache = new Map<string, { stamp: string, bytes: ArrayBuffer }>()
    _inflight = new Map<string, Promise<ArrayBuffer | null>>()
    fetch: typeof fetch

    constructor(o: { base?: string, scratch?: Scratch | null, fetch?: typeof fetch } = {}) {
        this.base = (o.base ?? '').replace(/\/+$/, '')
        this.scratch = o.scratch ?? null
        this.fetch = o.fetch ?? ((...a: Parameters<typeof fetch>) => fetch(...a))
        this.label = `origin${this.base ? ' ' + this.base : ''} (live, read-only)`
    }

    // manifest — the listing, refreshed by conditional GET when older than REFRESH_MS.  A failed refresh
    //  keeps the last good listing: a blip must not take the tree away mid-session.
    async manifest(force = false): Promise<Record<string, string>> {
        if (this._files && !force && Date.now() - this._at < REFRESH_MS) return this._files
        if (this._refreshing) return this._refreshing
        this._refreshing = (async () => {
            try {
                const r = await this.fetch(`${this.base}/__wormhole/tree`, { headers: this._etag ? { 'if-none-match': this._etag } : {} })
                if (r.status === 304 && this._files) { this._at = Date.now(); return this._files }
                if (!r.ok) throw new Error(`origin tree ${r.status}`)
                const body = await r.json() as { v: number, build: string, files: Record<string, string> }
                if (body?.v !== 1 || !body.files) throw new Error('origin tree: not a wormhole listing')
                if (this.build == null) this.build = body.build
                else if (body.build !== this.build && body.build !== this.build_moved) {
                    this.build_moved = body.build
                    console.warn(`☁️ OriginNav: the server moved to build ${body.build} under this tab (built ${this.build}) — new data, old code`)
                }
                this._files = body.files
                this._etag = r.headers.get('etag')
                this._at = Date.now()
                return this._files
            } catch (e) {
                if (this._files) { this._at = Date.now(); return this._files }
                throw e
            }
        })().finally(() => { this._refreshing = null })
        return this._refreshing
    }

    _join(dir_path: string, filename: string): string {
        return [...String(dir_path ?? '').split('/').filter(Boolean), filename].join('/')
    }

    // _bytes — one file's body, from the stamp-keyed cache or one request.  null = not in the tree.
    async _bytes(path: string): Promise<ArrayBuffer | null> {
        const files = await this.manifest()
        const stamp = files[path]
        if (!stamp) return null
        const hit = this._cache.get(path)
        if (hit && hit.stamp === stamp) return hit.bytes
        const running = this._inflight.get(path)
        if (running) return running
        const job = (async () => {
            const r = await this.fetch(`${this.base}/__wormhole/raw/${path.split('/').map(encodeURIComponent).join('/')}`)
            if (r.status === 404) return null
            if (!r.ok) throw new Error(`origin raw ${r.status} for ${path}`)
            const bytes = await r.arrayBuffer()
            // the response's own stamp is the truth for THESE bytes (the manifest may be a beat behind)
            const got = (r.headers.get('etag') ?? '').replace(/"/g, '') || stamp
            this._cache.set(path, { stamp: got, bytes })
            this.fetched++
            return bytes
        })().finally(() => { this._inflight.delete(path) })
        this._inflight.set(path, job)
        return job
    }

    // ── the nav surface ────────────────────────────────────────────────────────────────────────────
    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const local = await this.scratch?.read_file?.(dir_path, filename)
        if (local != null) return local
        const b = await this._bytes(this._join(dir_path, filename)).catch(() => null)
        return b == null ? null : new TextDecoder().decode(b)
    }
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const local = await this.scratch?.bin_read?.(dir_path, filename)
        if (local != null) return local
        return this._bytes(this._join(dir_path, filename)).catch(() => null)
    }
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const b = await this.bin_read(dir_path, filename)
        if (b == null) return null
        return { buffer: b.slice(offset, len == null ? undefined : offset + len), size: b.byteLength }
    }

    _no_write(what: string): never { throw new Error(`OriginNav is read-only (${what}) — writes belong to the person's folder or the editor`) }
    async write_file(dir_path: string, filename: string, content: string) { return this.scratch?.write_file ? this.scratch.write_file(dir_path, filename, content) : this._no_write(`${dir_path}/${filename}`) }
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer) { return this.scratch?.bin_write ? this.scratch.bin_write(dir_path, filename, bytes) : this._no_write(`${dir_path}/${filename}`) }
    async bin_append(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer) { return this.scratch?.bin_append ? this.scratch.bin_append(dir_path, filename, bytes) : this._no_write(`${dir_path}/${filename}`) }
    async bin_writer(dir_path: string, filename: string) { return this.scratch?.bin_writer ? this.scratch.bin_writer(dir_path, filename) : this._no_write(`${dir_path}/${filename}`) }
    async bin_rm(dir_path: string, filename: string): Promise<boolean> { return this.scratch?.bin_rm ? this.scratch.bin_rm(dir_path, filename) : false }

    async dir_at(path: string) { return this.dir(...path.split('/').filter(Boolean)) }

    // LISTING IS FREE — answered from the manifest, merged with scratch.
    async dir(...parts: string[]): Promise<Listing | null> {
        const files = await this.manifest()
        const prefix = parts.length ? parts.join('/') + '/' : ''
        const dirs = new Set<string>(), names = new Set<string>()
        let exists = !parts.length
        for (const p in files) {
            if (prefix && !p.startsWith(prefix)) continue
            exists = true
            const rest = p.slice(prefix.length).split('/')
            if (rest.length === 1) names.add(rest[0])
            else dirs.add(rest[0])
        }
        const live = this.scratch?.dir ? await this.scratch.dir(...parts).catch(() => null) : null
        if (live) {
            if (live.expand && !live.expanded) await live.expand().catch(() => {})
            exists = true
            for (const d of live.directories ?? []) dirs.add(d.name)
            for (const f of live.files ?? []) if (!f.name.startsWith('.')) names.add(f.name)
        }
        if (!exists) return null
        return {
            name: parts.length ? parts[parts.length - 1] : '/',
            directories: [...dirs].sort().map(name => ({ name })),
            files: [...names].sort().map(name => ({ name })),
            expanded: true,
            async expand() { /* already whole — the manifest is the listing */ },
        }
    }
}

// mount_origin_nav — resolves once the origin answers a listing; REJECTS when it has none (a static
//  host, or a server from before this existed), so the caller can fall back to the github mirror.
export async function mount_origin_nav(o: { base?: string, scratch?: Scratch | null, fetch?: typeof fetch } = {}): Promise<OriginNav> {
    const nav = new OriginNav(o)
    await nav.manifest(true)
    return nav
}
