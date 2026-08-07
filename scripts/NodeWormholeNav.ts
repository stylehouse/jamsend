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
    mounts: Record<string, string>   // name → absolute root (see below)
    rw: Record<string, boolean>      // which of those are WRITABLE; the rest refuse writes

    // `mounts` — extra READ-ONLY roots grafted in under a name of their own, so the nav can show a
    //  collection that does not live inside the repo (the container's `/music`, a NAS path, a mounted
    //   drive).  The daemon's `MUSIC=` knob is the one caller; `{ music: '/music' }` makes the nav
    //    answer `music/<file>` out of `/music/<file>` and list `music` among the root's directories.
    //  WHY A THIRD LAYER rather than pointing `base` at the music: `base` is the repo — the wormhole
    //   fixtures, the GhostList and the Ghost/gen trees all hang off it, so a daemon that repointed it
    //    would find music and lose everything it boots from.  Overlay/base is a SHADOWING pair (same
    //     namespace, one wins); a mount is a DISJOINT namespace, which is the honest shape for "this
    //      other tree is also visible here".
    //  READ-ONLY IS THE DEFAULT AND IS ENFORCED, not merely intended (`writeAbs` throws on a mounted
    //   rel unless that mount is declared `rw`): the collection is the owner's own files, and the
    //    daemon's whole safety story is that it does not write outside what it was handed.  A silent
    //     write that lands somewhere else would be worse than a throw.
    //  `Crate_nav_meander` needs no teaching: it walks whatever `dir_at`/`expand` report, and
    //   `Sounditron_muse` already probes the bases `['testsounds', 'music', '']` in that order — so a
    //    mount named `music` is found by the existing code with nothing on the ghost side to change.
    //  A mount may be WRITABLE — `{ path, rw: true }` instead of a bare path string.  That exists for
    //   exactly one shape, and it is the real deployment one: the user provisions their account from a
    //    BROWSER over FSA, which puts `.jamsend/account/<prepub>/toc.snap` inside the folder they
    //     granted — their music folder.  jamserve then has to write that same `.jamsend` (account
    //      mirror, radiostock, berth) while still booting the machine out of the repo (wormhole/,
    //       Ghost/, gen/) and still keeping its Story-snap scratch out of the user's music.  Three
    //        roots, three different rules — which the overlay/base PAIR cannot express, and a mount
    //         can: `.jamsend` → the share (rw), `music` → the share (ro), everything else → overlay.
    constructor(base: string, overlay: string, recording = false, mounts: Record<string, string | { path: string; rw?: boolean }> = {}) {
        this.base = base
        this.overlay = overlay
        this.recording = recording
        this.mounts = {}
        this.rw = {}
        for (const [name, m] of Object.entries(mounts)) {
            this.mounts[name] = typeof m === 'string' ? m : m.path
            if (typeof m !== 'string' && m.rw) this.rw[name] = true
        }
    }

    // mountFor — does `rel`'s FIRST segment name a mount?  Split on the first '/' only: the mount owns
    //  its whole subtree, and the remainder is resolved (and confined) against the mount's own root, so
    //   a `..` inside a mounted rel can no more escape `/music` than an ordinary rel can escape base.
    //  STRIP LEADING SLASHES FIRST.  `Swarm_account_dir(root, prepub)` is `(root||'') + '/.jamsend/…'`
    //   and every app caller passes root='', so the rel that actually arrives is `/.jamsend/account/…`
    //    — leading slash and all.  Splitting that naively makes the first segment the EMPTY STRING, no
    //     mount matches, and the account silently lands in the overlay instead of the user's library:
    //      measured, not imagined — the daemon cheerfully reported `🪪 account mirrored` while writing
    //       it to the scratch volume, which is the worst kind of pass (a green log for a wrong file).
    //  `path.join` has always treated a leading-slash rel as relative to root (Agent B's `confine`
    //   preserves that on purpose), so this is the same normalisation one step earlier.
    private mountFor(rel: string): { root: string; sub: string } | null {
        const clean = rel.replace(/^\/+/, '')
        const i = clean.indexOf('/')
        const head = i === -1 ? clean : clean.slice(0, i)
        const root = this.mounts[head]
        if (!root) return null
        return { root, sub: i === -1 ? '' : clean.slice(i + 1) }
    }

    // readAbs — the absolute paths a read should TRY, in precedence order.  A mounted rel resolves to
    //  exactly one candidate (its own root); everything else keeps the overlay-shadows-base pair the
    //   rest of this file has always used.
    private readAbs(rel: string): string[] {
        const m = this.mountFor(rel)
        if (m) return [this.confine(m.root, m.sub)]
        return [this.confine(this.overlay, rel), this.confine(this.base, rel)]
    }

    // native_path — the one PUBLIC escape hatch from rel-space to a real filesystem path, for the
    //  single case that genuinely needs it: handing a file to a NATIVE TOOL we spawn (ffmpeg, for
    //   the loudness/transcode seam — Daemon_todo §2.1/§2.2).  Reading the bytes and piping them to
    //    stdin would work for measurement and NOT for seeking, and a 30MB FLAC through a pipe to
    //     learn one number is silly, so the honest thing is to admit the path exists.
    //  READ SIDE ONLY, and deliberately so — it goes through `readAbs`, hence through `confine`, so
    //   it cannot name anything outside a mount/overlay/base, and it returns null rather than a path
    //    that isn't there.  There is no write twin: a native tool writes to a path WE choose under
    //     the overlay, never to one the caller named.
    native_path(rel: string): string | null {
        for (const abs of this.readAbs(rel)) if (existsSync(abs)) return abs
        return null
    }

    // fixture writes go to the real repo only while recording; everything else sandboxes.
    //  Mounted rels never reach here — `writeAbs` resolves those first (rw mount → its own root,
    //   otherwise a throw).  This is only the ordinary overlay/recording rule.
    private writeRoot(rel: string): string {
        return this.recording && rel.startsWith('wormhole/') ? this.base : this.overlay
    }

    // writeAbs — where a write LANDS.  A mount declared `rw` writes into its own root (that is the
    //  `.jamsend` case: the browser put the account there, so the daemon must update it in place);
    //   any other mount refuses, loudly.  Everything else keeps the overlay/recording rule above.
    private writeAbs(rel: string): string {
        const m = this.mountFor(rel)
        if (m) {
            // same leading-slash normalisation as mountFor — otherwise the name lookup misses and a
            //  writable mount reads as read-only (or worse, a read-only one as writable).
            const name = rel.replace(/^\/+/, '').split('/')[0]
            if (!this.rw[name]) throw new Error(`NodeWormholeNav: refusing write to the read-only mount "${name}" — rel="${rel}"`)
            return this.confine(m.root, m.sub)
        }
        return this.confine(this.writeRoot(rel), rel)
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
        for (const p of this.readAbs(rel)) {   // overlay shadows base; a mount answers alone
            if (isFileAt(p)) return readFileSync(p, 'utf8')
        }
        return null
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = this.writeAbs(rel)
        this.mkdirSecure(path.dirname(abs))
        this.writeSecure(abs, content, false)
    }

    // bin_read — read_file's binary twin: the raw bytes (no utf8 decode).  Overlay shadows base, same fall-through.
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const p of this.readAbs(rel)) {   // overlay shadows base; a mount answers alone
            if (isFileAt(p)) { const b = readFileSync(p); return b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength) as ArrayBuffer }
        }
        return null
    }

    // bin_write — write_file's binary twin: raw bytes into the sandbox (fixtures pass through only while
    //  recording, same writeRoot rule).  Completes the contract so a headless boot can write binary (WAVs).
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = this.writeAbs(rel)
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
        const abs = this.writeAbs(rel)
        this.mkdirSecure(path.dirname(abs))
        this.writeSecure(abs, bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes), true)
    }

    // read_range — bin_read's SEEKABLE twin: bytes [offset, offset+len) only (len omitted ⇒ to EOF), never
    //  the whole file — a real fd read of just the window + the total size, matching the browser navs.
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const p of this.readAbs(rel)) {   // overlay shadows base; a mount answers alone
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
        // A mounted rel lists from its own root ALONE — disjoint namespace, no shadowing (constructor).
        const m = this.mountFor(rel)
        const dirs = m ? [this.confine(m.root, m.sub)] : [this.base, this.overlay].map(r => this.confine(r, rel))
        if (!dirs.some(isDirAt)) return null
        const nav = this
        // At the ROOT listing, the mount names are directories that exist in the nav but on no single
        //  disk root — so they must be injected or a blind wander from '' could never reach them.
        //   (`Sounditron_muse` probes the base 'music' by name and would find it either way; a bare
        //    `Crate_nav_meander(nav, '', …)` would not, and that is the path a real Radio takes.)
        const extra = rel === '' ? Object.keys(this.mounts) : []
        return {
            name: parts[parts.length - 1] ?? '',
            directories: [] as { name: string }[],
            files: [] as { name: string }[],
            async expand() {
                const seen = new Map<string, boolean>()   // name → isDir (overlay shadows base)
                for (const d of dirs) {
                    if (!isDirAt(d)) continue
                    for (const ent of readdirSync(d, { withFileTypes: true })) seen.set(ent.name, ent.isDirectory())
                }
                for (const name of extra) if (isDirAt(nav.mounts[name])) seen.set(name, true)
                this.directories = [...seen].filter(([, isd]) => isd).map(([name]) => ({ name }))
                this.files       = [...seen].filter(([, isd]) => !isd).map(([name]) => ({ name }))
            },
        }
    }
}
