// wormhole_serve.ts — THE APP'S OWN TREE, READ-ONLY, FROM THE SERVER THAT SENT THE CODE.
//
//  WHY (2026-11-17, Atheory_todo "production").  A page with no repo folder (a listener, a phone, a music
//   share) reads its Books, Grounds and Wafts from a copy of the repo.  That copy was GITHUB
//    (LazyGithubNav): `main` on github, which lags the code this server is serving by however long the
//     owner leaves a commit unpushed.  b8bc stood on a Radio toc with no Spine:Jamsend for exactly that
//      reason — new code, old data, from two different sources.  The fix is ONE source: the process that
//       served the page's JavaScript also serves the files that JavaScript reads.  They cannot disagree.
//  Production needs a server anyway (the relay — friends cannot find each other without it), so this
//   is the same server doing one more thing, not a new dependency.  GitHub's only advantage, working
//    from a static host, was already spent on the relay.
//
//  THE TWO ROUTES — plain node (req, res), so `vite dev` (digePlugin) and a production node server
//   mount the same function.
//    GET /__wormhole/tree         → {v, build, at, files: {path: stamp}}  — every servable file under
//                                    the roots; `stamp` = `<mtimeMs>-<size>`, the cache key a tab holds.
//                                    ETag'd on the listing, so a poll that changed nothing is a 304.
//    GET /__wormhole/raw/<path>   → the file's bytes, with the same stamp as its ETag.
//  NOTHING WRITES.  Writes belong to the person (their folder, their OPFS) or to the editor terminal —
//   a listener's server never takes a file from a browser.
//
//  WHAT IS SERVED — the fence.  Only `wormhole/` and `Ghost/` (the same two subpaths the github mirror
//   carried: DEFAULT_SUBPATHS in WormholeOpfs), and inside them only what would be PUBLIC on github
//    anyway: no dot-files or dot-dirs (`.crswap`, `.tree_index.json`), no `_`-dirs (`_socklog`,
//     `_trace` — relay dumps, gitignored), no `shots/` (untracked screenshots), no `*.crswap`.
//   Paths are segment-checked (no `..`, no empty, no backslash) and resolved under the root, so no
//    request escapes it.  ⚠ The fence is a DENY list over a tree the owner keeps public on github;
//     a new private dir under wormhole/ must be added to SKIP_DIR here, or it is served.
//
//  `build` — THE VERSION-SKEW GUARD.  A tab that loaded build N and reads a file after the server moved
//   to build N+1 is new data under old code — the same bug class, just slower.  The tree carries the
//    server's build id; a tab that sees it change knows its own code is stale (OriginNav warns; the
//     reload policy is the production server's to decide).  Dev: `dev:<boot ms>` — vite reloads tabs on
//      a restart anyway.  Production: process.env.JAMSEND_BUILD, stamped by the build.
import { createHash } from 'node:crypto'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, resolve, sep } from 'node:path'

export const WORMHOLE_ROOTS = ['wormhole', 'Ghost']
const SKIP_DIR: Record<string, 1> = { shots: 1, node_modules: 1 }
const BOOT = Date.now()

export function wormhole_build(): string {
    return process.env.JAMSEND_BUILD || `dev:${BOOT}`
}

// servable — the fence, on repo-relative segments.  Shared by the walk and the raw route, so a file
//  is readable exactly when it is listed.
export function wormhole_servable(rel: string): boolean {
    if (!rel || rel.includes('\\') || rel.includes('\0')) return false
    const parts = rel.split('/')
    if (!WORMHOLE_ROOTS.includes(parts[0]) || parts.length < 2) return false
    for (let i = 0; i < parts.length; i++) {
        const p = parts[i]
        if (!p || p === '.' || p === '..' || p.startsWith('.')) return false
        if (i < parts.length - 1 && (p.startsWith('_') || SKIP_DIR[p])) return false
    }
    return !rel.endsWith('.crswap')
}

const stamp = (mtimeMs: number, size: number) => `${Math.floor(mtimeMs)}-${size}`

function walk(root_abs: string, rel: string, out: Record<string, string>) {
    let entries: ReturnType<typeof readdirSync>
    try { entries = readdirSync(join(root_abs, rel), { withFileTypes: true }) } catch { return }
    for (const e of entries) {
        const r = `${rel}/${e.name}`
        if (e.isDirectory()) {
            if (e.name.startsWith('.') || e.name.startsWith('_') || SKIP_DIR[e.name]) continue
            walk(root_abs, r, out)
        } else if (e.isFile() && wormhole_servable(r)) {
            try { const s = statSync(join(root_abs, r)); out[r] = stamp(s.mtimeMs, s.size) } catch { /* vanished mid-walk */ }
        }
    }
}

// wormhole_tree — the listing.  A stat sweep (~7k entries, kernel-cached), no reads: a stamp, not a
//  hash, because the tab only needs "is my cached copy this one?" and the raw route answers with the
//   same stamp.  (dige.ts hashes because Atlas must never adopt stale; here a mismatch merely refetches.)
export function wormhole_tree(repo_root: string): Record<string, string> {
    const out: Record<string, string> = {}
    for (const r of WORMHOLE_ROOTS) walk(repo_root, r, out)
    return out
}

// serve_wormhole — the http half.  Returns true when it handled the request.
export function serve_wormhole(repo_root: string, req: any, res: any): boolean {
    const url = new URL(req.url ?? '/', 'http://x')
    if (!url.pathname.startsWith('/__wormhole/')) return false
    if (req.method && req.method !== 'GET' && req.method !== 'HEAD') {
        res.statusCode = 405; res.setHeader('allow', 'GET, HEAD'); res.end('read-only'); return true
    }
    res.setHeader('cache-control', 'no-cache')
    res.setHeader('x-jamsend-build', wormhole_build())

    if (url.pathname === '/__wormhole/tree') {
        const t0 = Date.now()
        const files = wormhole_tree(repo_root)
        const payload = JSON.stringify(files)
        // the ETag is a function of the ANSWER (dige.ts learned this the hard way): build + listing
        const etag = `"${createHash('sha256').update(wormhole_build()).update(payload).digest('hex').slice(0, 16)}"`
        res.setHeader('etag', etag)
        if (req.headers?.['if-none-match'] === etag) { res.statusCode = 304; res.end(); return true }
        res.statusCode = 200
        res.setHeader('content-type', 'application/json')
        res.end(`{"v":1,"build":${JSON.stringify(wormhole_build())},"n":${Object.keys(files).length},"ms":${Date.now() - t0},"files":${payload}}`)
        return true
    }

    if (url.pathname.startsWith('/__wormhole/raw/')) {
        let rel: string
        try { rel = url.pathname.slice('/__wormhole/raw/'.length).split('/').map(decodeURIComponent).join('/') }
        catch { res.statusCode = 400; res.end(); return true }
        const root = resolve(repo_root)
        const abs = resolve(root, rel)
        if (!wormhole_servable(rel) || !abs.startsWith(root + sep)) { res.statusCode = 404; res.end(); return true }
        let s: ReturnType<typeof statSync>
        try { s = statSync(abs) } catch { res.statusCode = 404; res.end(); return true }
        if (!s.isFile()) { res.statusCode = 404; res.end(); return true }
        const etag = `"${stamp(s.mtimeMs, s.size)}"`
        res.setHeader('etag', etag)
        if (req.headers?.['if-none-match'] === etag) { res.statusCode = 304; res.end(); return true }
        res.statusCode = 200
        res.setHeader('content-type', rel.endsWith('.snap') || rel.endsWith('.g') || rel.endsWith('.md') ? 'text/plain; charset=utf-8' : 'application/octet-stream')
        res.end(req.method === 'HEAD' ? undefined : readFileSync(abs))
        return true
    }

    res.statusCode = 404; res.end(); return true
}
