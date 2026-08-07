// NodeWormholeNav — a node-fs nav for w:Wormhole, the UIless counterpart to the
//  browser WormholeNav (which wraps a DirectoryListing from the DirectoryOpener).
//  Production Housing.svelte.ts can't import node:fs (it's in the browser bundle), so
//   this lives in the harness and is injected through the A.c.nav seam the Wormhole
//    worker already leaves open (`if (!A.c.nav) …`).
//
// It is an OVERLAY: reads fall through real-repo → sandbox; writes land in the sandbox,
//  so booting compile-pipeline Books (Peregrination, Diffmatication, the Lake*/Leaf*
//   Peeroleum tests, LakeSurprise…) exercises their gen/ + Ghost/ writes WITHOUT
//    mutating the working tree.  The one exception is fixtures under wormhole/, which
//     pass through to the real repo only when `recording` is on (ACCEPT) — so re-record
//      lands real fixtures while plain runs leave even toc.snap untouched.
//
//   The FULL nav contract the worker uses (see Housing.svelte.ts Wormhole / fs_op + rw_op):
//    read_file / write_file / bin_read / bin_write / bin_append / read_range / dir / dir_at — kept at PARITY with
//     the browser WormholeNav / OpfsOverlayNav / RemoteWormholeNav so the harness is never a partial
//      nav that a binary-writing Book trips over headlessly.
import { readFileSync, writeFileSync, appendFileSync, mkdirSync, readdirSync, existsSync, statSync, openSync, readSync, closeSync, chmodSync } from 'node:fs'
import path from 'node:path'

const isDirAt = (p: string) => existsSync(p) && statSync(p).isDirectory()
const isFileAt = (p: string) => existsSync(p) && statSync(p).isFile()

export class NodeWormholeNav {
    base: string       // the real repo root — read-only fallback
    overlay: string    // a /tmp sandbox — where writes land
    recording: boolean // ACCEPT: let wormhole/ fixture writes pass through to base

    constructor(base: string, overlay: string, recording = false) {
        this.base = base
        this.overlay = overlay
        this.recording = recording
    }

    // fixture writes go to the real repo only while recording; everything else sandboxes
    private writeRoot(rel: string): string {
        return this.recording && rel.startsWith('wormhole/') ? this.base : this.overlay
    }

    // confine — every method below reaches disk ONLY through this (§8.4).  `path.join(root, rel)` alone
    //  lets a `..`-laden rel escape root (`path.join(root, '../../../etc/passwd')` walks right out); a peer
    //   request reaches rel through Housing's rw_op (Housing.svelte.ts's rw_dir/rw_name), so once RELAY=1
    //    joins the daemon to the network this is the seam that turns into an arbitrary-file primitive.
    //  join FIRST (so a rel that happens to start with '/' — Swarm_account_dir with root='' does exactly
    //   that — lands INSIDE root, the way path.join always treated it, rather than path.resolve's "leading
    //    slash resets to filesystem root" trap), THEN resolve to normalize any `..` the join left in.  A rel
    //     with `..` that still lands inside root (e.g. `wormhole/../Story/x`) is legitimate and must keep
    //      working — only an ESCAPE is refused, never the mere presence of `..`.  Compare against
    //       `root + path.sep` (plus the resolved-equals-root case) so `/root-evil` cannot pass as `/root/evil`.
    private confine(root: string, rel: string): string {
        const rootAbs = path.resolve(root)
        const abs = path.resolve(path.join(rootAbs, rel))
        if (abs !== rootAbs && !abs.startsWith(rootAbs + path.sep)) {
            throw new Error(`NodeWormholeNav: refusing path outside root — rel="${rel}" root="${rootAbs}"`)
        }
        return abs
    }

    // sensitive — is this RESOLVED path under a `.jamsend` segment (owner-local: account snaps carry the
    //  plaintext private key, Swarm_snap_keyed).  Checked on the resolved abs (not the raw rel) so a rel
    //   that merely MENTIONS `.jamsend` before a `..` cancels it back out isn't mistaken for the real thing.
    private sensitive(abs: string): boolean {
        return abs.split(path.sep).includes('.jamsend')
    }

    // secureJamsendDir — walked AFTER a plain (mode-less) recursive mkdirSync, never passed as that
    //  call's own `mode` — a recursive mkdirSync's mode is NOT leaf-only, it stamps EVERY directory
    //   the call creates, including ancestors ABOVE `.jamsend` (confirmed: mkdirSync(`OVERLAY/.jamsend/
    //    account/x`, {recursive,mode:0o700}) on a fresh OVERLAY left OVERLAY ITSELF at 0700, locking
    //     other users out of the unrelated wormhole/ subtree beside it — exactly the over-tightening
    //      CLAUDE.md/§8.4 warns against).  So creation stays at the ambient umask, and this walk fixes
    //       mode only from `.jamsend` down — never above it, whether the dir is fresh or predates this fix.
    private secureJamsendDir(dirAbs: string) {
        const parts = dirAbs.split(path.sep)
        const idx = parts.lastIndexOf('.jamsend')
        if (idx === -1) return
        for (let i = idx; i < parts.length; i++) {
            const p = parts.slice(0, i + 1).join(path.sep) || path.sep
            try { chmodSync(p, 0o700) } catch { /* best-effort — a dir a step up may not exist yet */ }
        }
    }

    // mkdirSecure — mkdirp to `dirAbs`, then, when it falls under `.jamsend`, both create at 0700 AND
    //  tighten any pre-existing ancestor that predates this fix (an account snap written before tonight
    //   is exactly the file that matters — CLAUDE.md's `Daemon_todo` §8.4).  Never touches wormhole/ or
    //    other ordinary project paths — those stay at the process umask, same as always.
    private mkdirSecure(dirAbs: string) {
        mkdirSync(dirAbs, { recursive: true })   // no `mode` here — see secureJamsendDir for why
        if (this.sensitive(dirAbs)) this.secureJamsendDir(dirAbs)
    }

    // writeSecure — writeFileSync, then, for a `.jamsend` path, both create at 0600 AND chmod-fix a
    //  file that already existed at the umask mode — writeFileSync's `mode` option only applies on
    //   CREATE, so an existing 644 account snap would otherwise keep leaking the plaintext key.
    private writeSecure(abs: string, data: string | Uint8Array, append: boolean) {
        const sensitive = this.sensitive(abs)
        if (append) appendFileSync(abs, data as any, sensitive ? { mode: 0o600 } : undefined)
        else writeFileSync(abs, data as any, sensitive ? { mode: 0o600 } : undefined)
        if (sensitive) { try { chmodSync(abs, 0o600) } catch { /* just wrote it; should never fail */ } }
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = this.confine(root, rel)
            if (isFileAt(p)) return readFileSync(p, 'utf8')
        }
        return null
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = this.confine(this.writeRoot(rel), rel)
        this.mkdirSecure(path.dirname(abs))
        this.writeSecure(abs, content, false)
    }

    // bin_read — read_file's binary twin: the raw bytes (no utf8 decode).  Overlay shadows base, same fall-through.
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = this.confine(root, rel)
            if (isFileAt(p)) { const b = readFileSync(p); return b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength) as ArrayBuffer }
        }
        return null
    }

    // bin_write — write_file's binary twin: raw bytes into the sandbox (fixtures pass through only while
    //  recording, same writeRoot rule).  Completes the contract so a headless boot can write binary (WAVs).
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = this.confine(this.writeRoot(rel), rel)
        this.mkdirSecure(path.dirname(abs))
        this.writeSecure(abs, bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes), false)
    }

    // bin_append — bin_write's STREAMING twin: extend a file at its END instead of replacing it whole, so a
    //  headless boot can stream a big asset chunk-at-a-time (the FSA WormholeNav.bin_append shape).  appendFileSync
    //   creates the file when absent (mode 'a'), so the FIRST append is the create — a caller appends from seq 0
    //    with no separate write.  Same writeRoot rule as bin_write: fixtures pass through to base only while
    //     recording, everything else sandboxes into the overlay.
    async bin_append(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = this.confine(this.writeRoot(rel), rel)
        this.mkdirSecure(path.dirname(abs))
        this.writeSecure(abs, bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes), true)
    }

    // read_range — bin_read's SEEKABLE twin: bytes [offset, offset+len) only (len omitted ⇒ to EOF), never
    //  the whole file — a real fd read of just the window + the total size, matching the browser navs.
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = this.confine(root, rel)
            if (!isFileAt(p)) continue
            const size = statSync(p).size
            const end = len == null ? size : Math.min(size, offset + len)
            const length = Math.max(0, end - offset)
            const buf = Buffer.alloc(length)
            const fd = openSync(p, 'r')
            try { if (length > 0) readSync(fd, buf, 0, length, offset) } finally { closeSync(fd) }
            return { buffer: buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength) as ArrayBuffer, size }
        }
        return null
    }

    // dir_at — dir() from a single '/'-joined path string (the discovery-site convenience).
    async dir_at(pth: string) { return this.dir(...pth.split('/').filter(Boolean)) }
    // returns a DirectoryListing-shaped object; .expand() merges base + overlay entries
    async dir(...parts: string[]): Promise<any | null> {
        const rel = parts.filter(Boolean).join('/')
        const roots = [this.base, this.overlay]
        if (!roots.some(r => isDirAt(this.confine(r, rel)))) return null
        const nav = this
        return {
            name: parts[parts.length - 1] ?? '',
            directories: [] as { name: string }[],
            files: [] as { name: string }[],
            async expand() {
                const seen = new Map<string, boolean>()   // name → isDir (overlay shadows base)
                for (const root of roots) {
                    const d = nav.confine(root, rel)
                    if (!isDirAt(d)) continue
                    for (const ent of readdirSync(d, { withFileTypes: true })) seen.set(ent.name, ent.isDirectory())
                }
                this.directories = [...seen].filter(([, isd]) => isd).map(([name]) => ({ name }))
                this.files       = [...seen].filter(([, isd]) => !isd).map(([name]) => ({ name }))
            },
        }
    }
}
