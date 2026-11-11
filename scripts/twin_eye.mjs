// twin_eye.mjs — two tabs of ONE browser profile (one headless context: shared IndexedDB, Web Locks, BroadcastChannel,
//  sessionStorage apart — exactly two real tabs), the second opened <gap>s after the first, printing each tab's identity /
//   hello / door / cohort lines.  Built 2026-11-11 to reproduce the twin-tab door bug (Identity_persist_todo §0.1); the
//    healthy read is: A `hello_ok addr=<prepub>`, B `👥 station standing at <prepub>_1` and `hello_ok addr=<prepub>_1`,
//     and NO bare hello_ok on B.  Mints a fresh identity in its own profile; touches nobody's tab.
//  node scripts/twin_eye.mjs [/BigSoundland] [gap secs=35] [hold secs=45]
import { chromium } from 'playwright'
import fs from 'node:fs'; import os from 'node:os'; import net from 'node:net'
const libs = os.homedir() + '/chromelibs/root'
process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu'].join(':')
const fc = os.homedir() + '/chromelibs/fonts.conf'; if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc
const path = process.argv[2] || '/BigSoundland', gap = +(process.argv[3] || 30), hold = +(process.argv[4] || 45)
const proxy = net.createServer(c => { const up = net.connect(9091, '172.17.0.1'); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
await new Promise(r => proxy.listen(0, '127.0.0.1', r))
const base = 'http://localhost:' + proxy.address().port
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] })
const ctx = await b.newContext({ viewport: { width: 1000, height: 700 } })   // ONE profile: shared IndexedDB, like two real tabs
await ctx.addInitScript(() => { window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError') }; try { localStorage.setItem('socklog', '1') } catch {} })
const t0 = Date.now(), T = () => ((Date.now() - t0) / 1000).toFixed(1)
const RX = /🪪|hello|door|sibling|suffix|taken|seat|👥|foreign|theft|stolen|contested|Identity|rehome|PAGEERROR/i
const open = async (tag) => {
  const p = await ctx.newPage()
  p.on('console', m => { const t = m.text(); if (RX.test(t)) console.log(T(), tag, t.slice(0, 230)) })
  p.on('pageerror', e => console.log(T(), tag, 'PAGEERROR', e.message.slice(0, 200)))
  await p.goto(base + path, { waitUntil: 'domcontentloaded', timeout: 60000 })
  try { const g = p.locator('.bg-listen'); await g.waitFor({ state: 'visible', timeout: 20000 }); await g.click(); console.log(T(), tag, 'gate: listen-only') } catch { console.log(T(), tag, 'gate: none') }
  return p
}
await open('A')
await new Promise(r => setTimeout(r, gap * 1000))
await open('B')
await new Promise(r => setTimeout(r, hold * 1000))
await b.close(); proxy.close(); process.exit(0)
