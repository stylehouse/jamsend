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
const [url, out, ticks = '4,12,25,40', W = '1280', H = '820'] = process.argv.slice(2)
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required', '--use-fake-ui-for-media-stream'] })
const ctx = await b.newContext({ viewport: { width: +W, height: +H }, deviceScaleFactor: 1 })
const p = await ctx.newPage()
const logs = []
p.on('console', m => { const t = m.text(); if (/error|warn|▣|Vyto|Voro|Story/i.test(t)) logs.push(t.slice(0, 200)) })
p.on('pageerror', e => logs.push('PAGEERROR ' + e.message.slice(0, 200)))
// A headless shell has no directory picker, and the gate answers that with "use Chrome" and HIDES the
//  listen-only door (boot_gate.svelte.ts: no_fsa ⇒ fsa_advice).  Wear a picker that always cancels, so
//   the gate offers the door it offers a real Chrome, and the eye takes it.
await p.addInitScript(() => { window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError') } })
await p.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 })
let t0 = Date.now()
// THE BOOT GATE: a room opens behind BootGate's "🎧 listen without a folder" — a headless eye has no folder
//  to pick, so it takes the listen-only door the moment it appears (up to 20s), like a first-time visitor.
try { const gate = p.locator('.bg-listen'); await gate.waitFor({ state: 'visible', timeout: 20000 }); await gate.click(); console.log('gate: listen-only, at', ((Date.now() - t0) / 1000).toFixed(1) + 's') }
catch { console.log('gate: none seen (already open, or a different gate)') }
for (const s of ticks.split(',').map(Number)) {
    const wait = s * 1000 - (Date.now() - t0); if (wait > 0) await p.waitForTimeout(wait)
    await p.screenshot({ path: `${out}_${s}s.png` })
    const st = await p.evaluate(() => {
        const svgs = [...document.querySelectorAll('svg.viewport')]
        return { viewports: svgs.length, paths: svgs.map(s => s.querySelectorAll('path.cell').length), texts: svgs.map(s => s.querySelectorAll('text').length),
                 folio: document.querySelectorAll('.folio text').length,
                 deck: [...document.querySelectorAll('.bs-deck')].map(e => e.textContent).join('|'),
                 step: document.querySelector('.bs-desk')?.nextElementSibling?.textContent?.slice(0, 0) }
    }).catch(e => String(e))
    console.log(`${s}s`, JSON.stringify(st))
}
console.log('--- console:'); for (const l of logs.slice(-25)) console.log(' ', l)
await b.close()
