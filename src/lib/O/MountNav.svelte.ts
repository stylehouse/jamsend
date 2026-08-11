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

// ── app_tree_decision — may we compose the app's own tree under someone's share? ──────────────────
//  The v1 problem, stated at Housing.svelte.ts:2113: a real listener grants their MUSIC folder, which
//   has no `wormhole/Story/Sounditron/toc.snap`, so they get no Books, no spine, no arrival — the app
//    works today only because the developer's share IS the repo checkout.  The fix is to mount the
//     app's own tree (the OPFS-from-github backend that already exists) under their grant.
//
//  THE DANGEROUS DIRECTION IS THE FALSE POSITIVE.  Deciding "no wormhole here" on a share that HAS one
//   mounts a github snapshot over the developer's real repo, and every Story write then lands silently
//    in OPFS scratch instead of on disk — work that looks saved and is not.  Stale directory handles
//     are a documented reality here (`WormholeNav._is_stale`, and mkdirp_fresh exists to recover from
//      them), so a single failed READ must never be read as absence.
//  Hence: absence is only believed from a SUCCESSFULLY EXPANDED root that listed at least one
//   directory and did not list `wormhole`.  Anything else answers 'unknown' and mounts nothing.
//  And an EDITOR boot is refused outright: it is the one role whose whole purpose is writing the real
//   project tree, so a silent redirect of its writes is the worst outcome available.  A runner or a
//    player has no such tree to lose and is exactly who this is for.
export type AppTree = 'share' | 'mount' | 'unknown' | 'gated'

export function app_tree_decision(o: { expanded: boolean, names: string[], boot_role?: string | null }): AppTree {
    if (!o.expanded) return 'unknown'          // never expanded / expand threw — no evidence either way
    if (!o.names.length) return 'unknown'      // an empty listing is far likelier a failed walk than a real share
    if (o.names.includes('wormhole')) return 'share'
    if (o.boot_role === 'editor') return 'gated'
    return 'mount'
}

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

type Mount = { at: string[], nav: NavLike, label: string, inner: string[] }

export type MountOpts = {
    label?: string
    // inner — where inside the MOUNTED nav the mount point actually lives.  Without this a mount is a
    //  bare rebase (`.jamsend/account/x` → `account/x`), which is right when the backend was made for
    //   the mount.  It is WRONG for the one mount v1 exists for: the app's own tree is an OPFS seed of
    //    the github repo, so its books are at `wormhole/Story/…` INSIDE it, not at its root.  Mounting
    //     it at `wormhole` with `inner:'wormhole'` maps `wormhole/Story/x` → `wormhole/Story/x` — an
    //      identity map today, but through a DIFFERENT backend, which is the entire point.
    inner?: string
}

const seg = (path: string): string[] => String(path ?? '').split('/').filter(Boolean)

export class MountNav {
    base: NavLike
    mounts: Mount[] = []
    is_mounted = true          // the seam a diagnostic recognises, beside is_opfs_github / is_remote
    label: string

    constructor(base: NavLike, label = 'mounted') {
        this.base = base
        this.label = label
        this._narrow()
    }

    // ── CAPABILITY NARROWING — the trap that makes a wrapper different from a router ────────────────
    //  Three real callers probe this object PATH-BLIND to choose a strategy before they have a path:
    //    Heist.g:689   `typeof nav.bin_append === 'function' || typeof nav.bin_writer === 'function'`
    //    Heist.g:3003  `typeof nav.read_range !== 'function'` → skip the cheap stat
    //    Heistation.g:414, LiesFunk.svelte:751 — same shape.
    //   A class method always answers "function", so an un-narrowed MountNav promises Heist a streaming
    //    landing and then silently no-ops the append on any backend that cannot do it — every downloaded
    //     track a zero-byte file, with nothing thrown.  So the OPTIONAL capabilities are presented as the
    //      INTERSECTION over base + every mount: shadow the prototype method with `undefined` on the
    //       instance, which `typeof` reads as absent, exactly as a plain backend without it would.
    //  This is the same law already written at Housing.svelte.ts:2694 — *"the honest subset — no partial
    //   interface that pretends to stream and silently rewrites"* — held one level further out.
    //  Narrowing is recomputed on every mount|unmount, never accumulated, so removing a thin mount
    //   RESTORES the capability rather than leaving the nav permanently degraded.
    static OPTIONAL = ['bin_append', 'bin_writer', 'read_range'] as const

    _narrow() {
        const navs: NavLike[] = [this.base, ...this.mounts.map(m => m.nav)]
        for (const k of MountNav.OPTIONAL) {
            const all = navs.every(n => typeof (n as any)[k] === 'function')
            if (all) delete (this as any)[k]                  // fall back to the prototype method
            else (this as any)[k] = undefined                 // shadow it: `typeof` now reads absent
        }
    }

    // mount — put `nav` at `at` (a '/'-joined path, e.g. 'wormhole' or '.jamsend').  Idempotent per
    //  point: re-mounting the same point REPLACES it, so a re-grant of the credentials directory does
    //   not stack two navs at one path.  Longest prefix wins at resolve time, so nesting is legal and
    //    order of registration never matters — which is what keeps this safe to call from a UI.
    mount(at: string, nav: NavLike, opts: MountOpts | string = {}) {
        const o: MountOpts = typeof opts === 'string' ? { label: opts } : opts
        const parts = seg(at)
        if (!parts.length) throw new Error('MountNav.mount: refusing to mount at the root — that is the base')
        this.mounts = this.mounts.filter(m => m.at.join('/') !== parts.join('/'))
        this.mounts.push({ at: parts, nav, label: o.label || (nav.label ?? at), inner: seg(o.inner ?? '') })
        this._narrow()
    }

    unmount(at: string) {
        const key = seg(at).join('/')
        this.mounts = this.mounts.filter(m => m.at.join('/') !== key)
        this._narrow()
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
        return { nav: best.nav, rest: [...best.inner, ...parts.slice(best.at.length)], via: best.label }
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
