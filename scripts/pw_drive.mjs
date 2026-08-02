// scripts/pw_drive.mjs — drive a REAL browser against the dev server and stream its console back
//  here, so UI debugging no longer needs a human to reload a tab and copy console junk.  Real browser
//   (same engine as a human tab), NOT the banned jsdom Story_cli boot.  TWO modes:
//
//  A) ATTACH to the human's already-running desktop Chrome/Brave over CDP (preferred — real profile,
//      real p2p identity, the live bug already on screen).  The human exposes it once:
//        1. FULLY QUIT Brave/Chrome, then relaunch it with:
//             --remote-debugging-port=9222 --remote-allow-origins=*
//           (binds 127.0.0.1:9222 on the host; --remote-allow-origins=* lets a non-DevTools client
//            open the CDP websocket, required since Chrome 111).
//        2. Bridge that host-loopback port to the docker gateway so this container can reach it:
//             socat TCP-LISTEN:9222,fork,reuseaddr,bind=172.17.0.1 TCP:127.0.0.1:9222   &
//           (no socat? node -e forwarder, or ssh -L 172.17.0.1:9222:127.0.0.1:9222 -N localhost)
//        3. node scripts/pw_drive.mjs --cdp=http://172.17.0.1:9222 20 --grep=KeepFace
//           add --reload to reload the attached :9091 tab; --goto=/BigSoundland to navigate it.
//
//  B) LAUNCH our own chromium (needs the browser system libs — the node:22-bookworm-slim claude
//      container lacks them & runs non-root, so this mode only works from host node or a deps-added
//       image; see spec/ulative/Migration_handover.md §5B):
//        node scripts/pw_drive.mjs /BigSoundland 12 [--grep=STR] [--head] [--url=ORIGIN]
import { chromium } from 'playwright'

const args = process.argv.slice(2)
const cdp = (args.find(a => a.startsWith('--cdp=')) ?? '').slice(6)
const goto = (args.find(a => a.startsWith('--goto=')) ?? '').slice(7)
const doReload = args.includes('--reload')
const path = args.find(a => !a.startsWith('-')) ?? '/BigSoundland'
const secs = Number(args.find(a => /^\d+$/.test(a)) ?? 15)
const grep = (args.find(a => a.startsWith('--grep=')) ?? '').slice(7)
const head = args.includes('--head')
const origin = (args.find(a => a.startsWith('--url=')) ?? '--url=http://172.17.0.1:9091').slice(6)

let browser, ctx, page
if (cdp) {
    console.log(`→ connectOverCDP ${cdp}`)
    browser = await chromium.connectOverCDP(cdp)
    ctx = browser.contexts()[0] ?? await browser.newContext()
    const pages = ctx.pages()
    page = pages.find(p => p.url().includes(':9091')) ?? pages[0] ?? await ctx.newPage()
    console.log(`  attached to page: ${page.url()}  (of ${pages.length} open)`)
} else {
    const URL = path.startsWith('http') ? path : origin + path
    console.log(`→ launch chromium, goto ${URL}`)
    browser = await chromium.launch({
        headless: !head,
        args: [
            '--autoplay-policy=no-user-gesture-required',
            '--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
            `--unsafely-treat-insecure-origin-as-secure=${origin}`,
            '--disable-features=IsolateOrigins,site-per-process',
        ],
    })
    ctx = await browser.newContext({ ignoreHTTPSErrors: true })
    page = await ctx.newPage()
}

let logs = 0, shown = 0, errs = 0
page.on('console', msg => {
    logs++
    const t = msg.text()
    if (grep && !t.includes(grep)) return
    if (shown++ < 500) console.log('  ▷', t.slice(0, 260))
})
page.on('pageerror', e => { errs++; console.log('  ✖ PAGEERROR', String(e).slice(0, 300)) })

if (goto) { const u = goto.startsWith('http') ? goto : origin + goto; console.log(`→ goto ${u}`); await page.goto(u, { waitUntil: 'domcontentloaded', timeout: 25000 }).catch(e => console.log('  ✖ goto', String(e).slice(0,150))) }
else if (!cdp) { const URL = path.startsWith('http') ? path : origin + path; await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 25000 }).catch(e => console.log('  ✖ GOTO FAILED', String(e).slice(0, 200))) }
if (doReload) { console.log('→ reload attached tab'); await page.reload({ waitUntil: 'domcontentloaded', timeout: 25000 }).catch(e => console.log('  ✖ reload', String(e).slice(0,150))) }

console.log(`→ watching console ${secs}s${grep ? ` (grep="${grep}")` : ''}…`)
await page.waitForTimeout(secs * 1000)

const probe = await page.evaluate(() => ({
    title: document.title,
    subtle: !!(globalThis.crypto && globalThis.crypto.subtle),
    cells: document.querySelectorAll('.vyto .cell').length,
    faces: document.querySelectorAll('.face-mold').length,
    idents: [...document.querySelectorAll('.vyto .ident')].map(e => e.textContent).slice(0, 12),
})).catch(e => ({ err: String(e).slice(0, 200) }))

const shot = '/tmp/claude-1000/-app/a988a149-8910-4946-a300-145d9e096fa5/scratchpad/pw_shot.png'
await page.screenshot({ path: shot }).catch(() => {})

console.log('─── RESULT ───')
console.log(JSON.stringify(probe, null, 1))
console.log('console lines total:', logs, '| shown:', shown, '| pageerrors:', errs, '| screenshot:', shot)

// ATTACH mode: never close the human's browser — just disconnect.  LAUNCH mode: tear down.
if (cdp) await browser.close().catch(() => {})   // playwright "close" on a CDP connection only disconnects
else await browser.close()
