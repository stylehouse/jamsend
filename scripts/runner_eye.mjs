// eye.mjs — open a page in headless chromium and photograph it over time.
//  node eye.mjs <url> <outprefix> [secs,secs,...] [w] [h]
import { chromium } from 'playwright'
import fs from 'node:fs'
import os from 'node:os'
// THE CONTAINER HAS NO ROOT AND NO CHROME LIBS.  `npx playwright install chromium-headless-shell` fetched the
//  browser (~/.cache/ms-playwright), and its shared libraries were pulled as .debs with a non-root apt
//   (`apt-get -o Dir::State=~/apt/... download`) and unpacked under ~/chromelibs/root — so point the loader there.
const libs = os.homedir() + '/chromelibs/root'
if (fs.existsSync(libs)) {
    process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu', process.env.LD_LIBRARY_PATH].filter(Boolean).join(':')
    // fonts the same way: DejaVu + Liberation unpacked under the same root, found through our own fonts.conf
    const fc = os.homedir() + '/chromelibs/fonts.conf'
    if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc
}
const argv = process.argv.slice(2)
// --eval='js expression string' — evaluated in-page at each tick (after window.__H exists on a dev
//  room like BigShapeland) and printed; the cheap way to answer a live-state question without another
//  console.log + compile + reload round trip. The expression runs with (H) in scope as window.__H.
const evalExprs = argv.filter(a => a.startsWith('--eval=')).map(a => a.slice(7))
// --click=<selector>@<sec>  press a thing at that second (repeatable); selector is a playwright locator string,
//   e.g. --click='.bs-stop:has-text("wave")@20'
const clicks = argv.filter(a => a.startsWith('--click=')).map(a => { const v = a.slice(8); const at = v.lastIndexOf('@'); return { sel: v.slice(0, at), sec: +v.slice(at + 1) } })
const [url, out, ticks = '4,12,25,40', W = '1280', H = '820'] = argv.filter(a => !a.startsWith('--'))
// 172.17.0.1 IS NOT A TRUSTWORTHY ORIGIN, and that alone blanked the room: Chrome sends no Sec-Fetch-* headers
//  to a plain-http non-localhost origin, and vite's transform middleware only compiles a `.go` (a Svelte
//   extension) into a module when `sec-fetch-dest: script` says a module asked — so every ghost came back
//    RAW with no MIME type ("Failed to load module script" ×36) and no Book ever stood.  Same reason the
//     dev server "must be reachable on localhost" (CLAUDE.md).  Tell Chrome the origin is secure.
//  The flag alone does not make Chrome SEND those headers (they go only to https/localhost), so the eye also
//   stands a TCP proxy on the container's own localhost and visits THROUGH it — the page then lives at
//    http://localhost:<port>, a trustworthy origin, exactly as the owner's tab does on the host.
import net from 'node:net'
let target = new URL(url)
let visit = url
if (target.hostname !== 'localhost' && target.hostname !== '127.0.0.1') {
    const [thost, tport] = [target.hostname, +(target.port || 80)]
    const proxy = net.createServer(c => { const up = net.connect(tport, thost); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
    await new Promise(r => proxy.listen(0, '127.0.0.1', r))
    const port = proxy.address().port
    target.hostname = 'localhost'; target.port = String(port)
    visit = target.toString()
    console.log('proxy: localhost:' + port + ' → ' + thost + ':' + tport)
}
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required', '--use-fake-ui-for-media-stream'] })
const ctx = await b.newContext({ viewport: { width: +W, height: +H }, deviceScaleFactor: 1 })
const p = await ctx.newPage()
const logs = []
p.on('console', m => { const t = m.text(); if (process.env.EYE_LOG === 'all' || /error|warn|▣|Vyto|Voro|Story/i.test(t)) logs.push(t.slice(0, 220)) })
p.on('pageerror', e => logs.push('PAGEERROR ' + e.message.slice(0, 200)))
p.on('requestfailed', r => logs.push('REQFAIL ' + r.url().slice(0, 160) + ' ' + (r.failure()?.errorText ?? '')))
p.on('response', r => { const ct = r.headers()['content-type'] ?? ''; const u = r.url(); if ((r.status() >= 400 || !ct) && !/\.(png|ico|woff2?)$/.test(u)) logs.push('RESP ' + r.status() + ' ct=' + JSON.stringify(ct) + ' ' + u.slice(0, 160)) })
// A headless shell has no directory picker, and the gate answers that with "use Chrome" and HIDES the
//  listen-only door (boot_gate.svelte.ts: no_fsa ⇒ fsa_advice).  Wear a picker that always cancels, so
//   the gate offers the door it offers a real Chrome, and the eye takes it.
await p.addInitScript(() => { window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError') } })
await p.goto(visit, { waitUntil: 'domcontentloaded', timeout: 60000 })
let t0 = Date.now()
// THE BOOT GATE: a room opens behind BootGate's "🎧 listen without a folder" — a headless eye has no folder
//  to pick, so it takes the listen-only door the moment it appears (up to 20s), like a first-time visitor.
try { const gate = p.locator('.bg-listen'); await gate.waitFor({ state: 'visible', timeout: 20000 }); await gate.click(); console.log('gate: listen-only, at', ((Date.now() - t0) / 1000).toFixed(1) + 's') }
catch { console.log('gate: none seen (already open, or a different gate)') }
const marks = [...new Set([...ticks.split(',').map(Number), ...clicks.map(c => c.sec)])].sort((a, b) => a - b)
for (const s of marks) {
    const wait = s * 1000 - (Date.now() - t0); if (wait > 0) await p.waitForTimeout(wait)
    for (const c of clicks.filter(c => c.sec === s)) {
        try { await p.locator(c.sel).first().click({ timeout: 3000 }); console.log(s + 's click', c.sel) } catch (e) { console.log(s + 's click FAILED', c.sel, String(e).slice(0, 80)) }
    }
    if (!ticks.split(',').map(Number).includes(s)) continue
    for (const expr of evalExprs) {
        try { const r = await p.evaluate((e) => { const H = window.__H; return eval(e) }, expr); console.log(s + 's eval', expr, '=>', JSON.stringify(r)) }
        catch (e) { console.log(s + 's eval FAILED', expr, String(e).slice(0, 150)) }
    }
    await p.screenshot({ path: `${out}_${s}s.png` })
    const st = await p.evaluate(() => {
        // any SVG standing in for the glass, whatever class it wears on THIS page (BigShapeland's is
        //  `svg.viewport`; other rooms may mount Vytui/Cytui inside their own wrapper) — fall back to
        //  every <svg> in the doc so the eye reports something real instead of a silent zero.
        let svgs = [...document.querySelectorAll('svg.viewport')]
        if (!svgs.length) svgs = [...document.querySelectorAll('svg')].filter(s => s.querySelector('path, text, ellipse, circle'))
        return { viewports: svgs.length, paths: svgs.map(s => s.querySelectorAll('path.cell, path').length), texts: svgs.map(s => s.querySelectorAll('text').length),
                 folio: document.querySelectorAll('.folio text').length,
                 faces: document.querySelectorAll('[class*="face" i], [class*="Face" i]').length,
                 deck: [...document.querySelectorAll('.bs-deck')].map(e => e.textContent).join('|') }
    }).catch(e => String(e))
    console.log(`${s}s`, JSON.stringify(st))
}
console.log('--- console:'); for (const l of logs.slice(process.env.EYE_LOG === 'all' ? -120 : -25)) console.log(' ', l)
await b.close()
