// glass_sketch.mjs — the HEADLESS SKETCH LOOP: draw a structure on the Vyto glass, look at it, change it, look again.
//
//   node scripts/glass_sketch.mjs [--sketch=static/vyto/sketch.json] [--out=/tmp/glass] [--watch] [--url=http://127.0.0.1:9091]
//
//  ONE headless chromium page, kept alive: it opens `/BigShapeland?B=VytoSketch` (the sketchpad Book — Ghost/V/VytoTesting.g),
//   waits for the glass, then for every iteration re-draws the sketch IN PLACE (VytoSketch_draw through the page — no
//    reload, ~1-3s) and writes `<out>/sketch_NNN.png` + one JSON metrics line.  `--watch` re-draws whenever the sketch
//     file changes, and whenever the RENDERER changes (Vytui.svelte / vyto_*.ts hot-reload into the live page by
//      themselves — the loop just waits for the HMR and shoots again).  Without --watch: one frame, then exit.
//  WHY THIS SHAPE (Glassbeast_todo §0 START HERE): the cheapest visual feedback is one browser that never reboots —
//   a boot costs ~30s, a re-draw costs ~2s.  The model (.g) is NOT hot: after editing a .g, compile it with LocalGen
//    (see §0.8) and the loop reloads the page by itself when the .go changes.
//  The agent LOOKS at the PNG (it is the only witness of the effect side — lettering, the feel of the cut) and READS
//   the metrics (cells drawn, rows with no room, labels, the render watchdog) for what a picture can hide.
import { chromium } from 'playwright'
import fs from 'node:fs'
import os from 'node:os'
import net from 'node:net'
import path from 'node:path'

const argv = process.argv.slice(2)
const kv = Object.fromEntries(argv.filter(a => a.startsWith('--') && a.includes('=')).map(a => { const i = a.indexOf('='); return [a.slice(2, i), a.slice(i + 1)] }))
const flags = new Set(argv.filter(a => a.startsWith('--') && !a.includes('=')))
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..')
// --book=VytoCodeCave drives the code cave (its sketch: static/vyto/code_sketch.json); default the sketchpad
const BOOK = kv.book ?? 'VytoSketch'
const SKETCH = path.resolve(ROOT, kv.sketch ?? (BOOK === 'VytoCodeCave' ? 'static/vyto/code_sketch.json' : 'static/vyto/sketch.json'))
const OUT = kv.out ?? '/tmp/glass'
const BASE = kv.url ?? process.env.GLASS_URL ?? 'http://127.0.0.1:9091'
const W = +(kv.w ?? 1280), H = +(kv.h ?? 820)
fs.mkdirSync(OUT, { recursive: true })

// the container's chromium libs, when present (this repo's dev box keeps them under ~/chromelibs — elsewhere a stock
//  `npx playwright install chromium` is enough)
const libs = os.homedir() + '/chromelibs/root'
if (fs.existsSync(libs)) {
    process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu', process.env.LD_LIBRARY_PATH].filter(Boolean).join(':')
    const fc = os.homedir() + '/chromelibs/fonts.conf'
    if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc
}

// a non-localhost dev server is proxied onto localhost — the app needs a SECURE CONTEXT (WebRTC, crypto.subtle)
let url = new URL(BASE)
let proxy = null
if (url.hostname !== 'localhost' && url.hostname !== '127.0.0.1') {
    const [th, tp] = [url.hostname, +(url.port || 80)]
    proxy = net.createServer(c => { const up = net.connect(tp, th); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
    await new Promise(r => proxy.listen(0, '127.0.0.1', r))
    url = new URL(`http://localhost:${proxy.address().port}`)
}
const sketch0 = JSON.parse(fs.readFileSync(SKETCH, 'utf8'))
const page_url = `${url.origin}/BigShapeland?B=${BOOK}${sketch0.deck ? '&deck=' + encodeURIComponent(sketch0.deck) : ''}`

const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required', '--use-fake-ui-for-media-stream'] })
const p = await (await b.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 })).newPage()
const watchdog = []
p.on('console', m => { const t = m.text(); if (/watchdog|Vyto.*threw|error/i.test(t)) watchdog.push(t.slice(0, 240)) })
p.on('pageerror', e => watchdog.push('pageerror: ' + String(e.message).slice(0, 240)))

async function boot() {
    // a headless page has no folder: stub the picker and press "listen without a folder", or the Book never starts
    await p.addInitScript(() => { window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError') } })
    await p.goto(page_url, { waitUntil: 'domcontentloaded', timeout: 90000 })
    try { const g = p.locator('.bg-listen'); await g.waitFor({ state: 'visible', timeout: 20000 }); await g.click() } catch { /* no gate */ }
    // the Book runs (fetches the sketch file, stands it) — wait for the glass to have cells
    for (let i = 0; i < 90; i++) {
        if (await p.evaluate(() => document.querySelectorAll('.vyto svg.viewport path.cell, .vyto svg.viewport circle.cell').length > 0).catch(() => false)) return
        await p.waitForTimeout(1000)
    }
    throw new Error('the glass never drew — is the dev server up, and VytoSketch compiled (.go has VytoSketch_draw)?')
}

// re-draw IN PLACE: find w:VytoSketch and the House that carries VytoSketch_draw, hand it the sketch
async function draw(sk) {
    return p.evaluate(([sk, book]) => {
        const H = window.__H; if (!H) return 'no window.__H — not BigShapeland?'
        let w = null, host = null; const seen = new Set()
        const walk = (n, d) => { if (!n || seen.has(n) || d > 9) return; seen.add(n)
            if (n.sc && n.sc.w === book) w = n
            if (!host && typeof n.VytoSketch_draw === 'function') host = n
            try { for (const k of n.o()) walk(k, d + 1) } catch { } }
        walk(H, 0); if (!host && typeof H.VytoSketch_draw === 'function') host = H
        if (!w || !host) return 'no w:' + book + ' yet'
        try { return 'drew ' + host.VytoSketch_draw(w, sk) } catch (e) { return 'draw threw ' + e.message }
    }, [sk, BOOK])
}

// wait until the glass stops changing: the cell geometry signature stable across 3 reads (≤ 15s)
async function settle() {
    let last = '', same = 0
    for (let i = 0; i < 50 && same < 3; i++) {
        await p.waitForTimeout(300)
        const sig = await p.evaluate(() => [...document.querySelectorAll('.vyto svg.viewport path.cell')].map(e => (e.getAttribute('d') || '').length + ':' + (e.getAttribute('data-key') || '')).join('|')).catch(() => '')
        same = sig && sig === last ? same + 1 : 0; last = sig
    }
    return same >= 3
}

async function metrics() {
    return p.evaluate(() => {
        const svg = document.querySelector('.vyto svg.viewport')
        const cells = svg ? svg.querySelectorAll('path.cell') : []
        const keys = [...cells].map(c => c.getAttribute('data-key')).filter(Boolean)
        const nested = svg ? svg.querySelectorAll('path.cell.nested').length : 0
        const vines = svg ? svg.querySelectorAll('path.vine, .crosslink, path.crosslink').length : 0
        const words = svg ? [...svg.querySelectorAll('text')].map(t => t.textContent.trim()).filter(Boolean) : []
        const noroom = [...document.querySelectorAll('*')].filter(e => e.children.length === 0 && /^NO ROOM$/i.test((e.textContent || '').trim())).length
        const noroom_rows = noroom ? [...document.querySelectorAll('*')].filter(e => e.children.length === 0 && /:/.test(e.textContent || '') && e.closest && e.parentElement && /NO ROOM/i.test(e.parentElement.textContent || '')).map(e => e.textContent.trim()).slice(0, 12) : []
        return { cells: cells.length, nested, vines, keys: keys.slice(0, 40), words: words.length, sample_words: words.slice(0, 24), noroom_rows }
    })
}

let n = 0
async function shoot(why) {
    const sk = JSON.parse(fs.readFileSync(SKETCH, 'utf8'))
    const drew = await draw(sk)   // every frame from THE FILE (the page booted on static/vyto/sketch.json)
    const calm = await settle()
    n++
    const file = path.join(OUT, `sketch_${String(n).padStart(3, '0')}.png`)
    const stage = p.locator('.vyto svg.viewport').first()
    try { await stage.screenshot({ path: file }) } catch { await p.screenshot({ path: file }) }
    await p.screenshot({ path: path.join(OUT, `sketch_${String(n).padStart(3, '0')}_page.png`) })
    const m = await metrics()
    const line = { n, why, drew, settled: calm, png: file, ...m, watchdog: watchdog.splice(0) }
    console.log(JSON.stringify(line))
    fs.writeFileSync(path.join(OUT, 'last.json'), JSON.stringify(line, null, 1))
}

// --dive=<key>,<key>,…,up — FILM a descent: press each cell in turn (its data-key, or a suffix of it; `up` = descend into the Landscape — the level left behind),
//  burst-capturing the fall and the surfacing (≈25 fps) into <out>/dive_NNNN.png.  Needs the `descend` stop on the deck.
async function press(key) {
    return p.evaluate((key) => {
        const els = [...document.querySelectorAll('.vyto svg.viewport path.cell')]
        const el = key === 'up' ? els.find(e => (e.getAttribute('data-key') || '').startsWith('landscape:'))
                                : (els.find(e => e.getAttribute('data-key') === key) ?? els.find(e => (e.getAttribute('data-key') || '').endsWith(key)))
        if (!el) return 'no cell ' + key + ' among ' + els.map(e => e.getAttribute('data-key')).slice(0, 12).join(' ')
        el.dispatchEvent(new MouseEvent('click', { bubbles: true }))
        return 'pressed ' + el.getAttribute('data-key')
    }, key)
}
// FILM MODE: the page's own clock is switched off (`__vy_film`) and THIS script steps the fall and the surfacing
//  frame by frame (`__vy_descend_at(u)`, `__vy_surface_at(u)`), one screenshot per step — so every frame is caught however
//   slowly the zoomed glass paints, and the same --dive makes the same film every run.  --fall=N / --rise=M frames.
async function film(keys) {
    let f = 0
    const FALL = Number(kv.fall ?? 36), RISE = Number(kv.rise ?? 18), HOLD = Number(kv.hold ?? 10)
    const grab = async () => { f++; try { await p.locator('.vyto svg.viewport').first().screenshot({ path: path.join(OUT, `dive_${String(f).padStart(4, '0')}.png`) }) } catch { f-- } }
    const frame = () => p.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))))
    await p.evaluate(() => { globalThis.__vy_film = 1 })
    for (let i = 0; i < HOLD; i++) await grab()                    // the level before the first fall
    for (const k of keys) {
        console.log(JSON.stringify({ dive: k, said: await press(k), frames_so_far: f }))
        for (let i = 1; i <= FALL; i++) {                            // THE FALL
            await p.evaluate((u) => globalThis.__vy_descend_at?.(u), i / FALL)
            await frame(); await grab()
        }
        await settle()                                               // the producer stands the new level
        for (let i = 0; i <= RISE; i++) {                            // THE SURFACING
            await p.evaluate((u) => globalThis.__vy_surface_at?.(u), i / RISE)
            await frame(); await grab()
        }
        for (let i = 0; i < HOLD; i++) await grab()                  // stand in the new level a moment
    }
    await p.evaluate(() => { globalThis.__vy_film = 0 })
    console.log(JSON.stringify({ filmed: f, out: OUT }))
}

await boot()
await shoot('boot')
if (kv.dive) { await film(kv.dive.split(',')); await b.close(); proxy?.close(); process.exit(0) }
if (!flags.has('--watch')) { await b.close(); proxy?.close(); process.exit(0) }

// WATCH: the sketch file → re-draw; the renderer (HMR'd into the page) → re-shoot; a .go (model) → reload + re-shoot
const watched = [SKETCH, path.join(ROOT, 'src/lib/O/Vytui.svelte'), ...fs.readdirSync(path.join(ROOT, 'src/lib/O')).filter(f => /^vyto_.*\.ts$/.test(f)).map(f => path.join(ROOT, 'src/lib/O', f)),
                 path.join(ROOT, 'src/lib/gen/V/Vyto.go'), path.join(ROOT, 'src/lib/gen/V/VytoTesting.go')]
const mtimes = Object.fromEntries(watched.map(f => [f, fs.existsSync(f) ? fs.statSync(f).mtimeMs : 0]))
console.error(`watching ${watched.length} files — edit the sketch or the renderer; Ctrl-C to stop`)
let busy = false
setInterval(async () => {
    if (busy) return
    const changed = watched.filter(f => fs.existsSync(f) && fs.statSync(f).mtimeMs !== mtimes[f])
    if (!changed.length) return
    busy = true
    for (const f of changed) mtimes[f] = fs.statSync(f).mtimeMs
    try {
        const rel = changed.map(f => path.relative(ROOT, f)).join(', ')
        if (changed.some(f => f.endsWith('.go'))) { await p.reload({ waitUntil: 'domcontentloaded' }); n = n; await boot().catch(e => console.error(String(e))) }
        else if (!changed.includes(SKETCH)) await p.waitForTimeout(1500)   // let Vite's HMR land in the page
        await shoot(rel)
    } catch (e) { console.error('shoot failed:', String(e).slice(0, 200)) }
    busy = false
}, 700)
