// MountNav — ONE wormhole namespace over SEVERAL backends.
//
// The owner, 2026-08-11: *"Wormhole needs to know mounts, so we can move wormhole/ to
//  .jamsend/wormhole and prefill it… virtual wormhole/ that isn't on disk and virtual .jamsend at
//   another share, but seeming to be there with the one unified w:Wormhole interface."*
//
// WHY A WRAPPER AND NOT A MOUNT TABLE INSIDE `WormholeNav` — this was got wrong twice before it was
//  got right, and the reason matters because the wrong shape LOOKS neater:
//   `WormholeNav` resolves every file method through `dir()`/`mkdirp()`, so routing those three walk
//    loops seems to buy mounts for the whole surface at three lines. It does not. `WormholeNav.dir()`
//     hands back a real `DirectoryListing`, and `read_file`/`bin_write`/`bin_writer` then call
//      `.getReader()` / `.getWriter()` / `.makeDirectory()` on it — whereas `OpfsOverlayNav.dir()`
//       deliberately returns a LISTING-SHAPED PROBE (`{name, directories, files, expand()}`) with no
//        file handles at all, because the only thing that ever needed it was `rw_op 'list'`. Route the
//         walk and every read on a mounted path dies on a missing `getReader`.
//  So mounting happens PER METHOD, delegating to the mounted nav's own same-named method. And once it
//   is per-method, it does not belong inside `WormholeNav` at all: nothing here is specific to a
//    DirectoryListing backend. A wrapper composes the implementations that already exist and edits
//     none of them — which is also why it is the safe change to the object every subsystem reads through.
//
// THE INTERFACE IS REAL, IT WAS JUST NEVER WRITTEN DOWN. `WormholeNav`, `OpfsOverlayNav` and
//  `RemoteWormholeNav` are three implementations of one duck-typed nav surface. `NavLike` below names
//   it, so the next implementation is checked against something.
//
// SAFETY OF THE PROBE SHAPE, checked and not assumed (2026-08-11): no ghost anywhere calls
//  `getReader`, `getWriter` or `makeDirectory` on a listing — `grep` over `Ghost/` returns nothing.
//   Every ghost caller does `nav.dir_at(p)` → `dl.expand()` → read `.files` / `.directories`, which is
//    exactly what the probe provides. So the backends really are interchangeable at the boundary the
//     app uses, and a mounted `dir_at` may return either shape.

export type NavLike = {
    dir?(...parts: string[]): Promise<any>
    dir_at?(path: string): Promise<any>
    mkdirp?(...parts: string[]): Promise<any>
    read_file?(dir_path: string, filename: string): Promise<string | null>
    bin_read?(dir_path: string, filename: string): Promise<ArrayBuffer | null>
    read_range?(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null>
    write_file?(dir_path: string, filename: string, content: string): Promise<void>
    bin_write?(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void>
    bin_append?(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void>
    bin_writer?(dir_path: string, filename: string): Promise<any>
    label?: string
}

type Mount = { at: string[], nav: NavLike, label: string }

const seg = (path: string): string[] => String(path ?? '').split('/').filter(Boolean)

export class MountNav {
    base: NavLike
    mounts: Mount[] = []
    is_mounted = true          // the seam a diagnostic recognises, beside is_opfs_github / is_remote
    label: string

    constructor(base: NavLike, label = 'mounted') {
        this.base = base
        this.label = label
    }

    // mount — put `nav` at `at` (a '/'-joined path, e.g. 'wormhole' or '.jamsend').  Idempotent per
    //  point: re-mounting the same point REPLACES it, so a re-grant of the credentials directory does
    //   not stack two navs at one path.  Longest prefix wins at resolve time, so nesting is legal and
    //    order of registration never matters — which is what keeps this safe to call from a UI.
    mount(at: string, nav: NavLike, label = '') {
        const parts = seg(at)
        if (!parts.length) throw new Error('MountNav.mount: refusing to mount at the root — that is the base')
        this.mounts = this.mounts.filter(m => m.at.join('/') !== parts.join('/'))
        this.mounts.push({ at: parts, nav, label: label || (nav.label ?? at) })
    }

    unmount(at: string) {
        const key = seg(at).join('/')
        this.mounts = this.mounts.filter(m => m.at.join('/') !== key)
    }

    // _pick — LONGEST-PREFIX match, so a mount at 'a/b' beats one at 'a' for 'a/b/c'.  Returns the nav
    //  that owns the path and the path REBASED onto it: a mount at '.jamsend' asked for
    //   '.jamsend/account/x' hands its own nav 'account/x'.  Rebasing is the whole trick — the mounted
    //    backend has no idea it is mounted, which is why an unmodified OpfsOverlayNav can serve one.
    _pick(parts: string[]): { nav: NavLike, rest: string[], via: string } {
        let best: Mount | null = null
        for (const m of this.mounts) {
            if (m.at.length > parts.length) continue
            if (m.at.some((p, i) => parts[i] !== p)) continue
            if (!best || m.at.length > best.at.length) best = m
        }
        if (!best) return { nav: this.base, rest: parts, via: 'base' }
        return { nav: best.nav, rest: parts.slice(best.at.length), via: best.label }
    }

    // which backend owns a path — for diagnostics and for the "where do my credentials live?" answer.
    //  Pure: resolves nothing, touches no disk.
    whose(path: string): string { return this._pick(seg(path)).via }

    // ── the surface, each method one rebase + one delegation ──────────────────────────────────────
    //  A backend that does not implement a method answers as ABSENT (null / no-op) rather than
    //   throwing a TypeError three frames deep in a ghost: a mount is a place, and a place that cannot
    //    do a thing has not got the thing.  The one exception is bin_writer, whose callers stream into
    //     the result — there, a missing implementation must be loud or bytes vanish silently.

    async dir(...parts: string[]): Promise<any> {
        const { nav, rest } = this._pick(parts)
        return nav.dir ? nav.dir(...rest) : null
    }
    async dir_at(path: string): Promise<any> { return this.dir(...seg(path)) }

    async mkdirp(...parts: string[]): Promise<any> {
        const { nav, rest } = this._pick(parts)
        return nav.mkdirp ? nav.mkdirp(...rest) : null
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const { nav, rest } = this._pick(seg(dir_path))
        return nav.read_file ? nav.read_file(rest.join('/'), filename) : null
    }

    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const { nav, rest } = this._pick(seg(dir_path))
        return nav.bin_read ? nav.bin_read(rest.join('/'), filename) : null
    }

    async read_range(dir_path: string, filename: string, offset: number, len?: number) {
        const { nav, rest } = this._pick(seg(dir_path))
        return nav.read_range ? nav.read_range(rest.join('/'), filename, offset, len) : null
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const { nav, rest } = this._pick(seg(dir_path))
        if (nav.write_file) await nav.write_file(rest.join('/'), filename, content)
    }

    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const { nav, rest } = this._pick(seg(dir_path))
        if (nav.bin_write) await nav.bin_write(rest.join('/'), filename, bytes)
    }

    async bin_append(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const { nav, rest } = this._pick(seg(dir_path))
        if (nav.bin_append) await nav.bin_append(rest.join('/'), filename, bytes)
    }

    async bin_writer(dir_path: string, filename: string): Promise<any> {
        const { nav, rest, via } = this._pick(seg(dir_path))
        if (!nav.bin_writer) throw new Error(`MountNav: ${via} has no bin_writer — refusing to swallow a stream for ${dir_path}/${filename}`)
        return nav.bin_writer(rest.join('/'), filename)
    }
}
