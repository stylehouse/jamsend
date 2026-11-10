// land_map.ts — the top-down view of the system for the land page (Ghost/L/LandPage.g, Land_map_read): Waft:Everything's areas
//  (each a What pointing at its area Waft, tagged with the Ground it loads as) JOINED to DocIndex's topics (the four sections of
//   spec/, each topic's front-door doc and companions).  The join is by doc: an area Waft cites its specs as `Doc:` rows, so a topic
//    whose front door (or a companion) an area cites belongs to that area, and the area takes the topic's section (I–IV).  Pure —
//     the caller says how to read a toc (the folder, or the copy shipped with the code), and gets plain objects back.
import { wafts_parse, EVERYTHING, UNSORTED } from './wafts_keep.js'

export type DocTopic = { sec: string, n: string, title: string, doc: string, more: string[] }
export type LandArea = {
    title: string, desc: string, waft: string, ground?: string, stands: string[], main?: string, role?: string,
    sec?: string, hue: number, topics: DocTopic[], defs: { method: string, desc: string, doc: string }[], cites: string[], books: string[]
}
export const LAND_SECTIONS: Record<string, string> = { I: 'metaphysics and the code', II: 'the app foundation', III: 'jamsend', IV: 'the visual end' }

// DocIndex's tables: `## I. …` opens a section; each `| n | **topic** | `front door` | what | companions |` row is a topic
export function docindex_parse(text: string): DocTopic[] {
    const out: DocTopic[] = []
    let sec = ''
    for (const line of String(text ?? '').split('\n')) {
        const h = /^## (I|II|III|IV)\./.exec(line)
        if (h) { sec = h[1]; continue }
        if (/^## /.test(line)) { sec = ''; continue }
        if (!sec) continue
        const cols = line.split(' | ')
        const m = /^\| ([0-9]+[a-z]?)$/.exec(cols[0] ?? '')
        if (!m || cols.length < 4) continue
        const ticks = (s: string) => [...String(s ?? '').matchAll(/`([^`]+\.md)`/g)].map(x => x[1])
        const doc = ticks(cols[2])[0]
        if (!doc) continue
        out.push({ sec, n: m[1], title: String(cols[1]).replace(/\*\*/g, '').trim(), doc, more: ticks(cols.slice(4).join(' | ')) })
    }
    return out
}

// one row's comma keys, as wafts_parse reads them (descs carry no comma — the keeping policy)
const kv_of = (line: string) => {
    const kv: Record<string, string> = {}
    for (const s of line.trim().split(',').slice(1)) { const i = s.indexOf(':'); if (i > 0) kv[s.slice(0, i)] = s.slice(i + 1) }
    return kv
}

export async function land_map(toc: (key: string) => Promise<string | undefined>, docindex_text: string): Promise<{ areas: LandArea[], problems: string[] }> {
    const problems: string[] = []
    const every = await toc(EVERYTHING)
    if (!every) return { areas: [], problems: [`no ${EVERYTHING} toc`] }
    const areas: LandArea[] = []
    for (const line of every.split('\n')) {
        const m = /^  What:([^,]+)/.exec(line)
        if (!m) continue
        const kv = kv_of(line)
        const waft = kv.FromWhat?.startsWith('Waft:') ? kv.FromWhat.slice(5) : ''
        if (!waft || waft === UNSORTED || waft === 'Credence') continue
        const a: LandArea = { title: m[1], desc: kv.desc ?? '', waft, stands: kv.stands ? kv.stands.split('|') : [], hue: 0,
            topics: [], defs: [], cites: [], books: [] }
        if (kv.ground) a.ground = kv.ground
        if (kv.main) a.main = kv.main
        if (kv.role) a.role = kv.role
        const parsed = wafts_parse((await toc(waft)) ?? '')
        if (!parsed) { problems.push(`${a.title}: no toc for Waft:${waft}`); areas.push(a); continue }
        a.books = parsed[2]
        // the tree: a What is an array; inside it `Doc:path` sets the doc the following `Point:method|desc` rows belong to
        const walk = (node: any[]) => {
            let doc = ''
            for (const c of node) {
                if (Array.isArray(c)) { walk(c); continue }
                if (typeof c !== 'string') continue
                if (c.startsWith('Doc:')) { doc = c.slice(4); if (!a.cites.includes(doc)) a.cites.push(doc) }
                else if (c.startsWith('Point:')) {
                    const [method, desc] = c.slice(6).split('|')
                    if (method && method !== 'undefined') a.defs.push({ method, desc: desc ?? '', doc })
                }
            }
        }
        for (const what of parsed[3]) walk(what)
        areas.push(a)
    }
    // the join: a topic goes to the first area citing its front door, else a companion; the area takes the section most of its topics sit in
    for (const t of docindex_parse(docindex_text)) {
        const cited = (d: string) => areas.find(a => a.cites.includes('src/lib/O/spec/' + d))
        const a = cited(t.doc) ?? t.more.map(cited).find(Boolean)
        if (!a) continue
        a.topics.push(t)
    }
    // hues spread evenly round the wheel in Everything's order — a hash bunched four areas into one green; stable while the order is
    areas.forEach((a, i) => { a.hue = Math.round(i * 360 / Math.max(1, areas.length) + 20) % 360 })
    // the area's section is where most of its topics sit (the wire cites Perf_todo, a section-I doc, but its own topics are II)
    for (const a of areas) {
        const n: Record<string, number> = {}
        for (const t of a.topics) n[t.sec] = (n[t.sec] ?? 0) + 1
        const best = Object.entries(n).sort((p, q) => q[1] - p[1])[0]
        if (best) a.sec = best[0]
    }
    return { areas, problems }
}
