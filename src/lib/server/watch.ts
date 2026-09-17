// watch.ts — A TAB'S FIXATION ON THE FILES IT HOLDS OPEN, kept by the process that has inotify.
//
//  WHY.  The dev server stopped watching wormhole/ on 2026-09-17 (vite.config `server.watch.ignored`):
//   5,243 files there are DATA, never imported, and the inotify watches they cost are budgeted per UID
//    on the host — the first boot as uid 1000 died ENOSPC on a Story fixture.  But a tab that has a
//     Waft open (wormhole/<Area>/toc.snap) or a Doc open (Ghost/**.g, src/**) does want to hear when
//      that ONE file moves under it.  The docindex push (vite.config digePlugin) covers source docs by
//       walking the whole corpus; nothing covered wormhole at all.
//  THE OWNER'S SHAPE (2026-09-17): "some client has to keep fixated on Docs and Wafts, so requests
//   watches for a big list of paths, to get them listened to — and they GC gently over time, if all
//    sockets are gone."  So: interest is PER SOCKET and PER PATH, the kernel watch is PER DIRECTORY
//     (one inotify watch serves every file in it, and an atomic write — tmp + rename, which is how
//      both Chrome's FSA and the Node nav land a file — shows up on the directory, not the inode),
//       and a directory whose last interested socket has gone is released a few minutes later, not
//        at once, so a tab reload does not churn the kernel.
//  WHAT IS PUSHED.  `{control:'changed', path, dige, mtime, size, event_at}` to every socket that
//   asked about that path — dige is the same first-16-hex sha256 the docindex rows carry (dige.ts),
//    so a tab can tell its own write coming back round from a foreign edit with the SAME `known.dige`
//     comparison Lies_docindex_heard already makes.  A file that vanished pushes `gone:1`.
//  WHAT IS NOT.  Contents (the tab reads them through its own nav, exactly as before); anything
//   outside the fenced roots; dotfiles; more than WATCH_MAX paths per socket.  Dev-only, like the
//    relay it rides.
import { watch as fs_watch, statSync, readFileSync, type FSWatcher } from 'node:fs'
import { createHash } from 'node:crypto'
import { resolve, dirname, posix } from 'node:path'

// Where a watch may land — the same fence the dige index walks plus wormhole (Wafts, fixtures).
const ROOTS = new Set(['Ghost', 'src', 'scripts', 'wormhole'])
const WATCH_MAX     = 4096      // paths one socket may hold interest in
const DIRS_MAX      = 2048      // directories under kernel watch at once (inotify budget headroom)
const SETTLE_MS     = 120       // an editor's write is several events; push once after the last
const GC_GRACE_MS   = 5 * 60_000 // a directory nobody wants is released this long after the last leaver
const GC_EVERY_MS   = 60_000

export type Pusher = (ws: object, frame: Record<string, unknown>) => void

function dig(text: string): string {
    const body = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text
    return createHash('sha256').update(Buffer.from(body, 'utf8')).digest('hex').slice(0, 16)
}

// A path is accepted only as a clean repo-relative posix path under a fenced root: no absolute, no
//  `..`, no dot-segments, no empty segments, one of ROOTS first.  Returns the normalised form or null.
export function sanePath(p: unknown): string | null {
    if (typeof p !== 'string' || !p || p.length > 512) return null
    const n = posix.normalize(p.replace(/\\/g, '/'))
    if (n.startsWith('/') || n.startsWith('..')) return null
    const segs = n.split('/')
    if (segs.length < 2 || !ROOTS.has(segs[0])) return null
    for (const s of segs) if (!s || s === '.' || s === '..' || s[0] === '.') return null
    return n
}

type Dir = { fsw: FSWatcher | null; paths: Set<string>; idle_since: number; pending: Map<string, ReturnType<typeof setTimeout>> }

export interface WatchDesk {
    // Register interest.  Returns what was accepted and what was refused (with why), so the caller can ack.
    watch(ws: object, paths: unknown[]): { ok: string[]; refused: { path: string; why: string }[] }
    unwatch(ws: object, paths: unknown[]): number
    // The socket is gone: release every interest it held (directories linger until GC).
    drop(ws: object): number
    // For a census/diagnostic line.
    readonly stats: { paths: number; dirs: number; sockets: number }
    close(): void
}

export function makeWatchDesk(repo_root: string, push: Pusher, log: (line: string) => void = () => {}): WatchDesk {
    const root = resolve(repo_root)
    const interest = new Map<string, Set<object>>()   // rel path → sockets that asked
    const held = new Map<object, Set<string>>()        // socket → rel paths it asked for
    const dirs = new Map<string, Dir>()                // rel dir → kernel watch + the paths it serves

    // One event on a directory: is it a file anyone wants?  Coalesce a burst (SETTLE_MS), then stat +
    //  dige once and push to every interested socket that is still open.
    function onDirEvent(dir: string, d: Dir, filename: string | Buffer | null) {
        if (!filename) return
        const rel = dir === '.' ? String(filename) : posix.join(dir, String(filename))
        if (!interest.has(rel)) return
        const t = d.pending.get(rel)
        if (t) clearTimeout(t)
        const event_at = Date.now()
        d.pending.set(rel, setTimeout(() => {
            d.pending.delete(rel)
            const socks = interest.get(rel)
            if (!socks || !socks.size) return
            let frame: Record<string, unknown>
            try {
                const abs = resolve(root, rel)
                const st = statSync(abs)
                const text = readFileSync(abs, 'utf8')
                frame = { control: 'changed', path: rel, dige: dig(text), mtime: Math.floor(st.mtimeMs), size: st.size, event_at }
            } catch {
                frame = { control: 'changed', path: rel, gone: 1, event_at }
            }
            let n = 0
            for (const ws of socks) { try { push(ws, frame); n++ } catch { /* a closing socket — drop() follows */ } }
            log(`👁 changed ${rel}${frame.gone ? ' (gone)' : ' ' + frame.dige} → ${n} socket(s)`)
        }, SETTLE_MS))
    }

    function dirOf(rel: string): string { const d = dirname(rel); return d === '' ? '.' : d }

    function ensureDir(dir: string): Dir | null {
        let d = dirs.get(dir)
        if (d) { d.idle_since = 0; return d }
        if (dirs.size >= DIRS_MAX) return null
        d = { fsw: null, paths: new Set(), idle_since: 0, pending: new Map() }
        try {
            const abs = resolve(root, dir)
            const dd = d
            d.fsw = fs_watch(abs, { persistent: false }, (_ev, filename) => onDirEvent(dir, dd, filename))
            d.fsw.on('error', () => { try { dd.fsw?.close() } catch {} ; dd.fsw = null })   // the dir went away; GC reaps it
        } catch {
            return null   // no such directory (yet) — the caller hears `refused`
        }
        dirs.set(dir, d)
        return d
    }

    function releasePath(rel: string, ws: object) {
        const socks = interest.get(rel)
        if (!socks) return
        socks.delete(ws)
        if (socks.size) return
        interest.delete(rel)
        const dir = dirOf(rel)
        const d = dirs.get(dir)
        if (!d) return
        d.paths.delete(rel)
        const t = d.pending.get(rel); if (t) { clearTimeout(t); d.pending.delete(rel) }
        if (!d.paths.size) d.idle_since = Date.now()   // linger: GC releases it after GC_GRACE_MS
    }

    const gc = setInterval(() => {
        const now = Date.now()
        let n = 0
        for (const [dir, d] of dirs) {
            if (d.paths.size || !d.idle_since || now - d.idle_since < GC_GRACE_MS) continue
            try { d.fsw?.close() } catch {}
            dirs.delete(dir); n++
        }
        if (n) log(`👁 gc released ${n} dir watch(es), ${dirs.size} held`)
    }, GC_EVERY_MS)
    ;(gc as any).unref?.()

    return {
        watch(ws, paths) {
            const ok: string[] = [], refused: { path: string; why: string }[] = []
            let mine = held.get(ws)
            if (!mine) held.set(ws, (mine = new Set()))
            for (const p of Array.isArray(paths) ? paths : []) {
                const rel = sanePath(p)
                if (!rel) { refused.push({ path: String(p).slice(0, 80), why: 'outside the fence' }); continue }
                if (mine.has(rel)) { ok.push(rel); continue }
                if (mine.size >= WATCH_MAX) { refused.push({ path: rel, why: `over ${WATCH_MAX} paths` }); continue }
                const d = ensureDir(dirOf(rel))
                if (!d) { refused.push({ path: rel, why: dirs.size >= DIRS_MAX ? 'dir budget' : 'no such directory' }); continue }
                d.paths.add(rel)
                let socks = interest.get(rel)
                if (!socks) interest.set(rel, (socks = new Set()))
                socks.add(ws)
                mine.add(rel)
                ok.push(rel)
            }
            return { ok, refused }
        },
        unwatch(ws, paths) {
            const mine = held.get(ws)
            if (!mine) return 0
            let n = 0
            for (const p of Array.isArray(paths) ? paths : []) {
                const rel = sanePath(p)
                if (!rel || !mine.has(rel)) continue
                mine.delete(rel); releasePath(rel, ws); n++
            }
            return n
        },
        drop(ws) {
            const mine = held.get(ws)
            if (!mine) return 0
            held.delete(ws)
            for (const rel of mine) releasePath(rel, ws)
            return mine.size
        },
        get stats() { return { paths: interest.size, dirs: dirs.size, sockets: held.size } },
        close() {
            clearInterval(gc)
            for (const d of dirs.values()) { try { d.fsw?.close() } catch {} ; for (const t of d.pending.values()) clearTimeout(t) }
            dirs.clear(); interest.clear(); held.clear()
        },
    }
}
