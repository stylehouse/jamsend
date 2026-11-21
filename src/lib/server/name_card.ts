// name_card.ts — "WHO INVITED ME?" ANSWERED BY THE SERVER, FOR A LINK THAT CARRIES NO `From=`.
//
//  WHY (owner 2026-11-21, printing blotters on prod): a blotter link is `?Iz=<token>` and nothing else, because
//   `&From=S` pushes every sheet QR from version 5 to 6 (level M holds 84 chars; a djamsend sheet link is ~83).
//    So the landing knows the inviter's prepub (off the token) and not their name, and said "by 7950f3".
//     The name is looked up instead: an inviter's tab POSTs a SIGNED card {from, pub, name, ts, sign}, and a
//      landing GETs `/__name?p=<prepub>`.
//
//  SIGNED, SO NOBODY ELSE CAN NAME YOU: the card verifies against its own `pub` (cluster_trust, the hello's
//   check) and `from` must be that pub's prepub.  Display only, like `From=` — the hello brings the real name
//    at the seal.  A name is public anyway (it rides every single invite's URL), so GET needs no auth.
//  BOUNDED: names ≤ 40 chars, POSTs 60 a minute, 5000 cards, kept in `.jamsend/name_cards.json` (gitignored).
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { verifyHeader, prepubOf } from '../cluster_trust'

const FILE = '.jamsend/name_cards.json'
const MAX_CARDS = 5000
const PER_MIN = 60
let cards: Record<string, { name: string, at: number }> | null = null
let window_at = 0
let window_n = 0

function load(repo_root: string) {
    if (cards) return cards
    try { cards = JSON.parse(readFileSync(join(repo_root, FILE), 'utf8')) } catch { cards = {} }
    return cards!
}
function save(repo_root: string) {
    const all = Object.entries(cards!)
    if (all.length > MAX_CARDS) cards = Object.fromEntries(all.sort((a, b) => b[1].at - a[1].at).slice(0, MAX_CARDS))
    mkdirSync(join(repo_root, '.jamsend'), { recursive: true })
    writeFileSync(join(repo_root, FILE), JSON.stringify(cards))
}

export function serve_name_card(repo_root: string, req: any, res: any): boolean {
    const url = new URL(req.url ?? '/', 'http://x')
    if (url.pathname !== '/__name') return false
    const answer = (code: number, body: any) => {
        res.statusCode = code; res.setHeader('content-type', 'application/json'); res.end(JSON.stringify(body))
    }
    if (req.method === 'GET') {
        const p = String(url.searchParams.get('p') || '').toLowerCase()
        const card = /^[0-9a-f]{16}$/.test(p) ? load(repo_root)[p] : null
        return answer(card ? 200 : 404, card ? { name: card.name } : { error: 'unknown' }), true
    }
    if (req.method !== 'POST') return answer(405, { error: 'GET or POST' }), true
    const now = Date.now()
    if (now - window_at > 60000) { window_at = now; window_n = 0 }
    if (++window_n > PER_MIN) return answer(429, { error: 'slow down' }), true
    let body = ''
    let over = false
    req.on('data', (c: Buffer) => { body += c; if (body.length > 4096) over = true })
    req.on('end', async () => {
        if (over) return answer(413, { error: 'too large' })
        try {
            const m = JSON.parse(body)
            const pub = typeof m.pub === 'string' ? m.pub : ''
            const name = typeof m.name === 'string' ? m.name.trim() : ''
            const fresh = typeof m.ts === 'number' && Math.abs(now - m.ts) < 300_000
            if (!pub || !name || name.length > 40 || !fresh || m.from !== prepubOf(pub)) return answer(400, { error: 'bad card' })
            const header = { control: 'name', from: m.from, pub, name, ts: m.ts, sign: m.sign }
            if (await verifyHeader(header, [pub]) !== pub) return answer(403, { error: 'bad sign' })
            const all = load(repo_root)
            if (all[m.from]?.name !== name) {
                all[m.from] = { name, at: now }
                save(repo_root)
                console.log(`📛 name card ${m.from.slice(0, 8)} = ${name}`)
            }
            answer(200, { ok: 1 })
        } catch (e: any) { answer(400, { error: String(e?.message || e).slice(0, 80) }) }
    })
    return true
}
