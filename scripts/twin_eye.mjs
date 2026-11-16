// twin_eye.mjs — tabs of ONE browser profile (one headless context: shared IndexedDB, Web Locks, BroadcastChannel,
//  sessionStorage apart — exactly real sibling tabs), driven through a PLAN of opens / reloads / closes / crashes, printing
//   each tab's identity / hello / door / cohort / storage lines and a verdict at the end.  Built 2026-11-11 to reproduce the
//    twin-tab door bug (Identity_persist_todo §0.1); grown 2026-11-15 into the reload-reload-kill simulator after Vingas came
//     up with two memory-only tabs and no friends (dexie_safe's probe lost a race on a swamped browser).
//  Mints a fresh identity in its own profile; touches nobody's tab.
//
//  node scripts/twin_eye.mjs [--path=/BigSoundland] [--plan="open:A wait:30 open:B wait:45"] [--slow-idb=6000]
//   plan steps (space-separated):  open:X  reload:X  close:X (a clean close — unload runs)  crash:X (the renderer dies: no
//    unload, locks freed by the browser)  wait:N (seconds)  slow:X (X's NEXT load delays the IndexedDB probe by --slow-idb ms)
//   legacy positional form still works:  node scripts/twin_eye.mjs /BigSoundland 35 45
//  The verdict, over the tabs still open: exactly ONE holds the bare name, every sibling stands at <prepub>_N, nobody is
//   memory-only, no PAGEERROR.  Exit 1 on a bad verdict, so a list of plans scripts.
import { chromium } from 'playwright'
import fs from 'node:fs'; import os from 'node:os'; import net from 'node:net'
const libs = os.homedir() + '/chromelibs/root'
process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu'].join(':')
const fc = os.homedir() + '/chromelibs/fonts.conf'; if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc
const flags = Object.fromEntries(process.argv.slice(2).filter(a => a.startsWith('--')).map(a => { const [k, ...v] = a.slice(2).split('='); return [k, v.join('=') || '1'] }))
const pos = process.argv.slice(2).filter(a => !a.startsWith('--'))
const path = flags.path || pos[0] || '/BigSoundland'
const plan = (flags.plan || `open:A wait:${+(pos[1] || 30)} open:B wait:${+(pos[2] || 45)}`).split(/\s+/).filter(Boolean)
const slow_ms = +(flags['slow-idb'] || 6000)
const proxy = net.createServer(c => { const up = net.connect(9091, '172.17.0.1'); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
await new Promise(r => proxy.listen(0, '127.0.0.1', r))
const base = 'http://localhost:' + proxy.address().port
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] })
const ctx = await b.newContext({ viewport: { width: 1000, height: 700 } })   // ONE profile: shared IndexedDB, like real tabs
await ctx.addInitScript(() => {
  window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError') }
  try { localStorage.setItem('socklog', '1') } catch {}
  // slow:X — delay ONLY dexie_safe's probe (a swamped browser's IndexedDB), armed per load through sessionStorage
  let ms = 0
  try { ms = +(sessionStorage.getItem('twin_slow_idb') || 0); sessionStorage.removeItem('twin_slow_idb') } catch {}
  if (ms > 0 && window.indexedDB) {
    const real = indexedDB.open.bind(indexedDB)
    indexedDB.open = function (name, ...rest) {
      if (name !== 'jamsend_probe') return real(name, ...rest)
      const fake = { onsuccess: null, onerror: null, onblocked: null, result: null, error: null }
      setTimeout(() => {
        const r = real(name, ...rest)
        r.onsuccess = () => { fake.result = r.result; console.log('⛁ twin_eye: the slowed probe answered after ' + ms + 'ms'); fake.onsuccess?.() }
        r.onerror = () => { fake.error = r.error; fake.onerror?.() }
        r.onblocked = () => fake.onblocked?.()
      }, ms)
      return fake
    }
  }
})
const t0 = Date.now(), T = () => ((Date.now() - t0) / 1000).toFixed(1)
const RX = /🪪|hello|door|sibling|suffix|taken|seat|👥|foreign|theft|stolen|contested|Identity|rehome|⛁|PAGEERROR|one socket/i
const tabs = {}   // X → { p, addr, mem, errors, life }
const watch = (tag, p) => {
  const t = tabs[tag]
  p.on('console', m => {
    const s = m.text()
    const h = /hello_ok addr=(\S+)/.exec(s); if (h) t.addr = h[1]
    if (/⛁ no browser storage/.test(s)) t.mem = s.slice(0, 120)
    if (RX.test(s)) console.log(T(), `${tag}#${t.life}`, s.slice(0, 230))
  })
  // the relay sockets this life holds open — under ?one_socket (Tribunal.g Carrier_join) the verdict wants exactly one
  p.on('websocket', ws => { if (!ws.url().includes('/relay')) return; t.socks = (t.socks || 0) + 1; ws.on('close', () => { t.socks = t.socks - 1 }) })
  p.on('pageerror', e => { t.errors.push(e.message.slice(0, 160)); console.log(T(), `${tag}#${t.life}`, 'PAGEERROR', e.message.slice(0, 200)) })
}
const gate = async (tag) => {
  const p = tabs[tag].p
  try { const g = p.locator('.bg-listen'); await g.waitFor({ state: 'visible', timeout: 20000 }); await g.click(); console.log(T(), tag, 'gate: listen-only') } catch { console.log(T(), tag, 'gate: none') }
}
const fresh_life = (tag) => { const t = tabs[tag]; t.life = (t.life || 0) + 1; t.addr = null; t.mem = null; t.socks = 0 }
const slow_next = new Set()
const arm_slow = async (tag) => { if (!slow_next.delete(tag)) return; await tabs[tag].p.evaluate((ms) => { try { sessionStorage.setItem('twin_slow_idb', String(ms)) } catch {} }, slow_ms) }
for (const step of plan) {
  const [verb, arg] = step.split(':')
  console.log(T(), '▸', step)
  if (verb === 'wait') { await new Promise(r => setTimeout(r, +arg * 1000)); continue }
  if (verb === 'slow') { slow_next.add(arg); continue }
  if (verb === 'open') {
    tabs[arg] = { errors: [], life: 0 }
    fresh_life(arg)
    const p = tabs[arg].p = await ctx.newPage()
    watch(arg, p)
    if (slow_next.has(arg)) { await p.goto(base + '/favicon.ico').catch(() => {}); await arm_slow(arg) }
    await p.goto(base + path, { waitUntil: 'domcontentloaded', timeout: 60000 })
    await gate(arg); continue
  }
  const t = tabs[arg]
  if (!t?.p) { console.log(T(), '✗ no open tab', arg); continue }
  if (verb === 'reload') { await arm_slow(arg); fresh_life(arg); await t.p.reload({ waitUntil: 'domcontentloaded', timeout: 60000 }); await gate(arg); continue }
  if (verb === 'close') { await t.p.close({ runBeforeUnload: true }); t.p = null; continue }
  if (verb === 'crash') { const cdp = await ctx.newCDPSession(t.p); await cdp.send('Page.crash').catch(() => {}); t.p = null; continue }
  console.log(T(), '✗ unknown step', step)
}
// the verdict, over the tabs still open
const live = Object.entries(tabs).filter(([, t]) => t.p)
const bare = live.filter(([, t]) => t.addr && !/_\d+$/.test(t.addr))
const bad = []
if (bare.length !== 1) bad.push(`${bare.length} tab(s) hold the bare name (want 1): ${bare.map(([k]) => k).join(',') || '—'}`)
for (const [k, t] of live) {
  if (!t.addr) bad.push(`${k}: never hello_ok'd`)
  if (t.mem) bad.push(`${k}: memory-only — ${t.mem}`)
  if (t.errors.length) bad.push(`${k}: ${t.errors.length} PAGEERROR (${t.errors[0]})`)
  if (path.includes('one_socket') && t.socks !== 1) bad.push(`${k}: ${t.socks} relay sockets open — armed for one socket`)
}
console.log('\n── verdict for plan: ' + plan.join(' '))
for (const [k, t] of live) console.log(`   ${k}#${t.life}  addr=${t.addr || "—"}  sockets=${t.socks}${t.mem ? "  MEMORY-ONLY" : ""}`)
console.log(bad.length ? bad.map(s => '   ✗ ' + s).join('\n') : '   ✓ one bare holder, siblings suffixed, storage real')
await b.close(); proxy.close(); process.exit(bad.length ? 1 : 0)
