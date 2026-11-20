// log_drop.ts — A TAB POSTS ITS CONSOLE HERE, AND IT LANDS IN wormhole/_trace/.
//
//  WHY (2026-11-20, a friend's phone played no sound and left nothing to read).  A phone has no folder, so the
//   socklog dump (LiesLies, onto the tab's own FSA wormhole) never happens, and an un-armed tab cannot be reached
//    by `runner_ask console --player=`.  The console ring (sockcap.ts concap) is always on, so the tab can just
//     SEND it: the 🪪 "send log" button in the Door POSTs the ring as text, and it becomes
//      wormhole/_trace/drop-<pub8>-<time>.txt for `ls -t wormhole/_trace` to find.
//
//  WRITE-ONLY AND BOUNDED: it is the one write a stranger's browser can make on this box, so a drop is capped
//   (256KB), the endpoint takes at most 20 a minute, and only the newest 60 drops are kept.  Nothing is read back.
import { mkdirSync, readdirSync, statSync, unlinkSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const DIR = 'wormhole/_trace'
const MAX_BYTES = 256 * 1024
const KEEP = 60
const PER_MIN = 20
let window_at = 0
let window_n = 0

export function serve_log_drop(repo_root: string, req: any, res: any): boolean {
    const url = new URL(req.url ?? '/', 'http://x')
    if (url.pathname !== '/__log') return false
    if (req.method !== 'POST') { res.statusCode = 405; res.setHeader('allow', 'POST'); res.end('post only'); return true }
    const now = Date.now()
    if (now - window_at > 60000) { window_at = now; window_n = 0 }
    if (++window_n > PER_MIN) { res.statusCode = 429; res.end('slow down'); return true }
    const pub = String(url.searchParams.get('pub') || 'anon').replace(/[^0-9a-z]/gi, '').slice(0, 8) || 'anon'
    const chunks: Buffer[] = []
    let size = 0
    let over = false
    req.on('data', (c: Buffer) => { size += c.length; if (size > MAX_BYTES) over = true; else chunks.push(c) })
    req.on('end', () => {
        if (over) { res.statusCode = 413; res.end('too large'); return }
        try {
            const dir = join(repo_root, DIR)
            mkdirSync(dir, { recursive: true })
            // the box's local time, so "about 6:02" finds it with ls
            const d = new Date(now), p = (n: number) => String(n).padStart(2, '0')
            const stamp = `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`
            const name = `drop-${pub}-${stamp}.txt`
            writeFileSync(join(dir, name), Buffer.concat(chunks))
            console.log(`📤 log drop ${name} (${size}b)`)
            prune(dir)
            res.statusCode = 200; res.end(name)
        } catch (e: any) { res.statusCode = 500; res.end(String(e?.message || e)) }
    })
    return true
}

function prune(dir: string) {
    const drops = readdirSync(dir).filter(f => f.startsWith('drop-'))
        .map(f => ({ f, t: statSync(join(dir, f)).mtimeMs })).sort((a, b) => b.t - a.t)
    for (const d of drops.slice(KEEP)) { try { unlinkSync(join(dir, d.f)) } catch {} }
}
