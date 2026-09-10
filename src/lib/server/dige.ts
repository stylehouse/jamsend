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
import { mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
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

// ── THE GEN SWEEP — the same trick, aimed at the OTHER thing this box polls ──────────────────────
//  `Creduler_reswap` (LiesLies) watches the compiled ghosts for a hot-swap by firing one HEAD per
//   CREDULER_GHOST — 38 serial round trips — every 2 seconds, on every editor and runner tab, forever.
//    Its own comment called that "correct + cheap"; measured on a live runner 2026-09-09 with the
//     Electrode tap it is 280–315ms per sweep and the single largest recurring cost on the tab, which
//      is the constant background tax behind *"unimpressed with its ability to change Doc quickly"*.
//  Nothing about the watch was wrong except its shape: 38 questions where one answers.  The gen tree
//   is a directory this process owns, so it can hash it once and hand back the whole map, and the
//    ETag then makes the common case — nothing changed — a 304 with no body at all.
//  DELIBERATELY A SECOND ENDPOINT, not a `roots=gen` on the first: `gen` is in the SKIP list above
//   because Atlas must never index generated code, and widening the walk to please a second caller
//    would put the generated tree back in the census.  Two callers, two questions, two doors.
const GEN_DIR = 'src/lib/gen'
const GEN_EXT: Record<string, 1> = { go: 1 }

function walk_gen(root_abs: string, rel: string, out: Record<string, Served>) {
    let entries: any[]
    try {
        entries = readdirSync(join(root_abs, rel), { withFileTypes: true }) as any
    } catch {
        return
    }
    for (const e of entries) {
        if (e.name.startsWith('.')) continue
        const child = `${rel}/${e.name}`
        if (e.isDirectory()) { walk_gen(root_abs, child, out); continue }
        if (!e.isFile()) continue
        if (!GEN_EXT[e.name.split('.').pop() ?? '']) continue
        const abs = join(root_abs, child)
        let st
        try { st = statSync(abs) } catch { continue }
        const mtime = Math.floor(st.mtimeMs)
        const size = st.size
        const had = memo.get(child)
        if (had && had.mtime === mtime && had.size === size) { out[child] = [had.dige, mtime, size]; continue }
        let text: string
        try { text = readFileSync(abs, 'utf8') } catch { continue }
        const d = dig(text)
        memo.set(child, { mtime, size, dige: d })
        out[child] = [d, mtime, size]
    }
}

// gen_diges — every compiled ghost's content hash, keyed the way `Lies_gen_path` names them
//  (`gen/L/Atlas.go`), so the caller needs no path arithmetic.
export function gen_diges(repo_root: string): Record<string, Served> {
    const out: Record<string, Served> = {}
    walk_gen(resolve(repo_root), GEN_DIR, out)
    const keyed: Record<string, Served> = {}
    for (const k of Object.keys(out)) keyed[k.replace(/^src\/lib\//, '')] = out[k]
    return keyed
}

// ── THE STATUS WAFT — the whole corpus's dige+mtime+size as a particle tree on disk ──────────────
//  The owner, 2026-09-10, correcting the plan twice in two sentences: *"one off-tab walk producing one
//   Waft that carries the whole reading of ALL 700 documents, their mtime or even dige"* and *"the
//    status-of-everything Waft is just dige + mtime + size"*.
//  So: not an endpoint, not a Mag, not a page — ONE Waft, written to the wormhole, opened by the tab
//   with `deWaft` — code the machine has had since the beginning.  `/__atlas/dige` was this same fact
//    wearing a bespoke JSON shape; this is the fact as the machine's own matter, and it retires that.
//  WHY A FILE AND NOT A RESPONSE: a response has to be asked for.  A file in the wormhole is simply
//   there, the tab already knows how to open one, and the dev server already watches the tree that
//    produces it — so "push" costs nothing but a rewrite on change.
//
//  THE FORMAT IS NOT INVENTED HERE.  It is what the real encoder emits, read off a live round-trip
//   rather than inferred (2026-09-10):
//        Waft:<key>
//          Doc:<path>,dige:<hex>,mtime=<num>,size=<num>
//   Two spaces per depth; a STRING value takes `key:value`, a NUMBER takes `key=value`.  Getting that
//    backwards would decode as a string and nothing would complain, so `scripts/StatusWaft.spec.ts`
//     gates this by decoding what THIS function writes with the tab's own decoder.
const WAFT_KEY = 'Docindex'

export function status_waft(repo_root: string, roots: string[]): { snap: string, docs: number, skipped: string[] } {
    const dige = atlas_diges(repo_root, roots)
    const paths = Object.keys(dige).sort()
    const lines: string[] = [`Waft:${WAFT_KEY}`]
    const skipped: string[] = []
    for (const p of paths) {
        // a comma or a newline in a path would be eaten by the peel parser, which splits sc on commas —
        //  so such a path is SKIPPED and named, never silently emitted to corrupt every row after it
        if (/[,\n\r]/.test(p)) { skipped.push(p); continue }
        const [d, mtime, size] = dige[p]
        lines.push(`  Doc:${p},dige:${d},mtime=${mtime},size=${size}`)
    }
    return { snap: lines.join('\n') + '\n', docs: paths.length - skipped.length, skipped }
}

// write_status_waft — emit it where a Waft lives, so the tab opens it with no new code at all.
//  Returns null when nothing changed, so a watcher can call this on every event without churning disk.
export function write_status_waft(repo_root: string, roots: string[] = DEFAULT_ROOTS): { path: string, docs: number, changed: boolean } {
    const { snap, docs } = status_waft(repo_root, roots)
    const dir = join(resolve(repo_root), 'wormhole', WAFT_KEY)
    const file = join(dir, 'toc.snap')
    let had: string | null = null
    try { had = readFileSync(file, 'utf8') } catch { had = null }
    if (had === snap) return { path: file, docs, changed: false }
    mkdirSync(dir, { recursive: true })
    writeFileSync(file, snap, 'utf8')
    return { path: file, docs, changed: true }
}

// serve_diges — the http half.  Returns true when it handled the request.
export function serve_diges(repo_root: string, req: any, res: any): boolean {
    const url = new URL(req.url ?? '/', 'http://x')
    if (url.pathname === '/__gen/dige') {
        const t0g = Date.now()
        const gd = gen_diges(repo_root)
        const payload_g = JSON.stringify(gd)
        const etag_g = `"${createHash('sha256').update(payload_g).digest('hex').slice(0, 16)}"`
        if (req.headers['if-none-match'] === etag_g) { res.statusCode = 304; res.end(); return true }
        res.statusCode = 200
        res.setHeader('content-type', 'application/json')
        res.setHeader('etag', etag_g)
        res.setHeader('cache-control', 'no-cache')
        res.end(`{"v":1,"gens":${Object.keys(gd).length},"ms":${Date.now() - t0g},"dige":${payload_g}}`)
        return true
    }
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
