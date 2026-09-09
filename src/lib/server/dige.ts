// dige.ts — THE INDEX'S CHEAP HALF, SERVED FROM WHERE THE BYTES LIVE.
//
//  WHY THIS EXISTS.  Atlas already memoizes: a Dexie `atlas` row per doc, adopted when
//   mapper+mtime+size match, which skips the PARSE entirely.  What it deliberately does NOT skip is
//    the READ — `Atlas_cache_adopt` reads the file and diges it before trusting the row, because
//     mtime+size is a hint and never proof (two edits in one wall-clock second that leave the byte
//      length alone would silently adopt stale).  That refusal is right and this does not undo it.
//
//  But it means a warm boot pays ~724 FSA reads, 40 per polite pass, to learn that nothing changed.
//   That is the "ton of docs reading every time".  The fix is not to weaken the truth — it is to
//    compute the truth ONCE, where the bytes already are, and let the tab ask for it in a sentence.
//     The dev server holds the repo.  It can hash it.  One request replaces 724 reads, and the
//      decider is still a content hash, not a listing's guess.
//
//  WHY NOT A NEW DOCKER SERVICE (the owner's third option, 2026-09-09).  Nothing here needs one: no
//   new container to keep alive, no compose change, and — the load-bearing reason — the index is a
//    fact about THIS host's files, so it belongs to the process that already serves them.  A second
//     service would have to be told where the repo is; the dev server simply is there.  If this
//      later grows into serving whole %Maps (the language-server ambition), that is this endpoint
//       doing more, not a different road: the walk, the skip list and the memo are already here.
//
//  WHY IT IS SAFE TO SERVE.  Dev-only (mounted from `configureServer`, which never runs in a build).
//   It answers with hashes, never contents.  Roots are validated as single path segments and the
//    walk is fenced to the repo root, so no query can escape it; extensions are allowlisted.
//
//  THE MEMO.  One in-process Map keyed by path, holding {mtime, size, dige}.  Every request re-stats
//   (cheap, and the kernel has it cached) and re-hashes only what moved.  So the FIRST call after a
//    server start pays the full hash of the corpus and every call after it pays a stat sweep.
//
//  "IT TELLS US WHEN IT THINKS WE NEED TO REINDEX" — that is the ETag.  The payload's own hash is
//   the version of the whole index; a tab that polls with If-None-Match gets a 304 and does nothing.
//    No push, no subscription, no second socket: the question "has anything changed?" costs one
//     conditional GET, and the answer, when it is yes, IS the new index.
import { createHash } from 'node:crypto'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, resolve } from 'node:path'

// Atlas's own constants are the defaults; a caller may narrow them but never widen past this.
//  (Ghost/L/Atlas.g — ATLAS_ROOTS / ATLAS_SKIP / ATLAS_EXT.  Kept in step by hand: a drift here
//   costs a fallback read per un-served doc, never a wrong answer, because the tab falls back to
//    reading any path this map does not mention.)
const DEFAULT_ROOTS = ['Ghost', 'src', 'scripts']
const SKIP: Record<string, 1> = { gen: 1, node_modules: 1, history: 1, shelved: 1, '.git': 1, '.svelte-kit': 1 }
const EXT: Record<string, 1> = { g: 1, svelte: 1, ts: 1, md: 1 }

type Memo = { mtime: number; size: number; dige: string }
type Served = [string, number, number]   // [dige, mtime, size]
const memo = new Map<string, Memo>()

// dig — byte-identical to the browser's `dig` (Y.svelte.ts): sha256 of the UTF-8 bytes, first 16
//  hex.  Blob.text() strips a leading BOM and node's utf8 read does not, so strip it here or a
//   BOM'd file would disagree with the tab forever and re-read every pass.
function dig(text: string): string {
    const body = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text
    return createHash('sha256').update(Buffer.from(body, 'utf8')).digest('hex').slice(0, 16)
}

function walk(root_abs: string, rel: string, out: Record<string, Served>) {
    let entries: ReturnType<typeof readdirSync>
    try {
        entries = readdirSync(join(root_abs, rel), { withFileTypes: true }) as any
    } catch {
        return   // a root that isn't there is not an error — Atlas walks what exists
    }
    for (const e of entries as any[]) {
        if (e.name.startsWith('.') && e.name !== '.git') continue
        const child = rel ? `${rel}/${e.name}` : e.name
        if (e.isDirectory()) {
            if (SKIP[e.name]) continue
            walk(root_abs, child, out)
            continue
        }
        if (!e.isFile()) continue
        const ext = e.name.split('.').pop() ?? ''
        if (!EXT[ext]) continue
        const abs = join(root_abs, child)
        let st
        try { st = statSync(abs) } catch { continue }
        // FLOORED, and it matters: node's mtimeMs is a float with sub-ms precision, while the tab's
        //  side of this comparison is FSA's `File.lastModified` — integer milliseconds.  Unfloored,
        //   the two would disagree on essentially every file and the whole index would degrade into
        //    a silent no-op that still looked like it was working.  (Which is why Atlas counts its
        //     hits and misses onto the census row rather than trusting that this line is right.)
        const mtime = Math.floor(st.mtimeMs)
        const size = st.size
        const had = memo.get(child)
        if (had && had.mtime === mtime && had.size === size) { out[child] = [had.dige, mtime, size]; continue }
        let text: string
        try { text = readFileSync(abs, 'utf8') } catch { continue }
        const d = dig(text)
        memo.set(child, { mtime, size, dige: d })
        // mtime+size ride ALONG WITH the hash on purpose: they are what the tab checks the hash
        //  against.  A dige alone would be a claim about bytes at an unstated moment; a dige beside
        //   the metadata it was taken from is a claim the tab can corroborate against its own
        //    independent stat of the same file.  See Atlas_cache_adopt for what it does with them.
        out[child] = [d, mtime, size]
    }
}

// atlas_diges — the whole answer: every indexable file's path → [dige, mtime, size], under the roots.
export function atlas_diges(repo_root: string, roots: string[]): Record<string, Served> {
    const out: Record<string, Served> = {}
    const base = resolve(repo_root)
    for (const r of roots) {
        // a root is ONE plain segment; anything else (a slash, a dot-dot, an absolute path) is
        //  refused rather than sanitised, so there is no clever escape to reason about
        if (!/^[A-Za-z0-9_-]+$/.test(r)) continue
        walk(base, r, out)
    }
    return out
}

// serve_diges — the http half.  Returns true when it handled the request.
export function serve_diges(repo_root: string, req: any, res: any): boolean {
    const url = new URL(req.url ?? '/', 'http://x')
    if (url.pathname !== '/__atlas/dige') return false
    const asked = (url.searchParams.get('roots') ?? '').split(',').map(s => s.trim()).filter(Boolean)
    const roots = asked.length ? asked : DEFAULT_ROOTS
    const t0 = Date.now()
    const dige = atlas_diges(repo_root, roots)
    // THE ETAG HASHES THE INDEX, NOT THE ENVELOPE.  Hashing the whole body looked right and was
    //  wrong: `ms` is this request's own duration, so every response differed from the last by a
    //   millisecond and no conditional GET ever hit — the poll this exists to make free would have
    //    re-sent 58KB forever, quietly.  The ETag must be a function of the ANSWER alone.
    const payload = JSON.stringify(dige)
    const etag = `"${createHash('sha256').update(payload).digest('hex').slice(0, 16)}"`
    if (req.headers['if-none-match'] === etag) {
        res.statusCode = 304
        res.end()
        return true
    }
    res.statusCode = 200
    res.setHeader('content-type', 'application/json')
    res.setHeader('etag', etag)
    res.setHeader('cache-control', 'no-cache')
    res.end(`{"v":1,"docs":${Object.keys(dige).length},"ms":${Date.now() - t0},"dige":${payload}}`)
    return true
}
