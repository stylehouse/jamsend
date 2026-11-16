// friends_eye.mjs — TWO STRANGERS BECOME FRIENDS, headless.  One Chromium, two separate profiles (A and B) on one localhost
//  origin: A opens the music page, names itself and mints an invite through the Door; B opens that invite, names itself and
//   joins.  Then both sit for a while and the script reads each console and each relay frame log.  Made for the one-socket
//    rollout (Social_demarcation_todo §0.5 stage 2: "flip on the HEADLESS newcomer only — the walk is the gate"), but it is just
//     the seal walk: drop ONE_SOCKET=1 and it walks the two-socket road.
//  Usage: node scripts/friends_eye.mjs <origin e.g. http://172.17.0.1:9091> <outprefix> [secs after the join, default 60]
//   ONE_SOCKET=1 arms both tabs (?one_socket — Tribunal.g Carrier_join).  Outputs <out>.{A,B}.console.log/.ws.log/.txt/.png.
//  Verdict (exit 1 when bad): B's invite reaches "sealed" both ways (a %Pier each side — the Door says a friend), and under
//   ONE_SOCKET each tab ends on ONE relay socket that carried both the role and the identity.
//  Needs ~/chromelibs (see runner_eye.mjs).  Mints two fresh identities and touches nobody's tab.  Run it alone (one Chromium).
import { chromium } from 'playwright'
import fs from 'node:fs'; import os from 'node:os'; import net from 'node:net'
const libs = os.homedir() + '/chromelibs/root'
if (fs.existsSync(libs)) { process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu', process.env.LD_LIBRARY_PATH].filter(Boolean).join(':'); const fc = os.homedir() + '/chromelibs/fonts.conf'; if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc }
const [origin, out, afterArg = '60'] = process.argv.slice(2)
if (!origin || !out) { console.error('usage: node scripts/friends_eye.mjs <origin> <outprefix> [secs]'); process.exit(2) }
const ONE = !!process.env.ONE_SOCKET
const target = new URL(origin); const [thost, tport] = [target.hostname, +(target.port || 80)]
const proxy = net.createServer(c => { const up = net.connect(tport, thost); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
await new Promise(r => proxy.listen(0, '127.0.0.1', r))
const base = `http://localhost:${proxy.address().port}`   // localhost = a secure context, so crypto.subtle and the rest exist
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] })
const t0 = Date.now(); const at = () => ((Date.now() - t0) / 1000).toFixed(1) + 's '
const tab = async (name) => {
  const ctx = await b.newContext({ viewport: { width: 1100, height: 800 } })
  const p = await ctx.newPage()
  await p.addInitScript(() => { try { localStorage.setItem('socklog', '1') } catch {} })
  // the invite is shown as a QR; its "copy link" button writes the URL to the clipboard — keep a copy where the script can read it
  await p.addInitScript(() => { try { const c = navigator.clipboard || {}; Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { ...c, writeText: async (t) => { window.__copied = String(t) }, readText: async () => window.__copied || '' } }) } catch {} })
  const log = fs.createWriteStream(`${out}.${name}.console.log`)
  const lines = []
  p.on('console', m => { const t = m.text().replace(/\n/g, ' ⏎ ').slice(0, 400); lines.push(t); log.write(at() + t + '\n') })
  p.on('pageerror', e => { lines.push('PAGEERROR ' + e); log.write(at() + 'PAGEERROR ' + String(e).slice(0, 300) + '\n') })
  const wsl = fs.createWriteStream(`${out}.${name}.ws.log`)
  const sockets = []
  p.on('websocket', ws => {
    if (!ws.url().includes('/relay')) return
    const s = { tag: ws.url().split('?')[1] || 'bare', open: true, kinds: new Set(), controls: new Set() }
    sockets.push(s)
    ws.on('close', () => { s.open = false; wsl.write(at() + `x [${s.tag.slice(0, 22)}] closed\n`) })
    const one = (dir) => (f) => {
      if (typeof f.payload !== 'string') { const nl = f.payload.indexOf(10); try { const j = JSON.parse(f.payload.subarray(0, nl).toString()); s.kinds.add(j.type) } catch {} return }
      let t = f.payload
      try { const j = JSON.parse(t); if (j.control) { s.controls.add(dir + j.control); t = 'control:' + j.control + (j.addr ? ' ' + j.addr : '') } else if (j.header) { s.kinds.add(j.header.type); t = j.header.type + ' ' + j.header.from + '→' + j.header.to } } catch {}
      if (/control:log|^ping |^pong |^ack /.test(t)) return
      wsl.write(at() + dir + ' [' + s.tag.slice(0, 22) + '] ' + t.slice(0, 160) + '\n')
    }
    ws.on('framereceived', one('<')); ws.on('framesent', one('>'))
  })
  return { name, ctx, p, lines, sockets, log, wsl }
}
const arm = (u) => ONE ? u + (u.includes('?') ? '&' : '?') + 'one_socket' : u
const try_ = async (what, fn) => { try { await fn(); console.log(at() + what) } catch (e) { console.log(at() + what + ' FAILED: ' + String(e).split('\n')[0].slice(0, 140)) } }
const name_self = async (t, who) => {
  await try_(`${t.name}: listen without a folder`, () => t.p.locator('.bg-listen').first().click({ timeout: 8000, force: true }))
  await t.p.waitForTimeout(3000)
  await try_(`${t.name}: named ${who}`, async () => { await t.p.locator('input.ip-name').first().fill(who, { timeout: 8000 }); await t.p.locator('input.ip-name').first().press('Enter') })
}
const A = await tab('A')
await A.p.goto(arm(`${base}/BigSoundland`), { waitUntil: 'domcontentloaded' })
await A.p.waitForTimeout(9000)
// a stranger with no invite sees the Door as a closed cell — open it to reach the namer and the invite button
await try_('A: listen without a folder', () => A.p.locator('.bg-listen').first().click({ timeout: 8000, force: true }))
await A.p.waitForTimeout(3000)
// the satellite cell is the button (Cellui: aria-label "switch to <label>") — it swaps the Door into the main seat
await try_('A: open the Door', async () => {
  for (let k = 0; k < 30; k++) {
    if (await A.p.locator('input.ip-name, input.df-input, .ip-go-mint').count()) return
    if (k === 8 && process.env.EYE_DEBUG) { await A.p.screenshot({ path: `${out}.A.door.png` }); fs.writeFileSync(`${out}.A.door.txt`, await A.p.evaluate(() => [...document.querySelectorAll('input,button')].map(e => e.tagName + '.' + e.className + ' ' + (e.textContent || e.placeholder || '').trim().slice(0, 40)).join('\n') + '\n----\n' + document.body.innerText.slice(0, 2000))) }
    await A.p.evaluate(() => { const e = document.querySelector('[aria-label="switch to Door"]'); if (e) e.click() })
    await A.p.waitForTimeout(1000)
  }
  throw new Error('the Door never showed a name field')
})
await A.p.waitForTimeout(3000)
if (process.env.EYE_DEBUG) { await A.p.screenshot({ path: `${out}.A.door.png` }); fs.writeFileSync(`${out}.A.door.txt`, await A.p.evaluate(() => [...document.querySelectorAll('input,button')].map(e => e.tagName + '.' + e.className + ' ' + (e.textContent || e.placeholder || '').trim().slice(0, 40)).join('\n') + '\n----\n' + document.body.innerText.slice(0, 2000))) }
// the Door's own namer (DoorFace .df-input) for a stranger; the InvitePanel's (.ip-name) when it shows that instead
await try_('A: named Ana', async () => { const f = A.p.locator('input.df-input, input.ip-name').first(); await f.fill('Ana', { timeout: 8000 }); await f.press('Enter') })
await A.p.waitForTimeout(4000)
if (process.env.EYE_DEBUG) fs.writeFileSync(`${out}.A.named.txt`, await A.p.evaluate(() => [...document.querySelectorAll('input,button')].map(e => e.tagName + '.' + e.className + ' ' + (e.textContent || e.placeholder || '').trim().slice(0, 40)).join('\n') + '\n----\n' + document.body.innerText.slice(0, 2000)))
await A.p.waitForTimeout(4000)
await try_('A: invite', () => A.p.locator('.ip-go-mint').first().click({ timeout: 8000, force: true }))
await A.p.waitForTimeout(3000)
if (process.env.EYE_DEBUG) { fs.writeFileSync(`${out}.A.minted.txt`, await A.p.evaluate(() => [...document.querySelectorAll('input,button,a')].map(e => e.tagName + '.' + e.className + ' ' + (e.textContent || e.placeholder || '').trim().slice(0, 40)).join('\n') + '\n----\n' + document.body.innerText.slice(0, 2000))) }
let link = ''
for (let i = 0; i < 30 && !link; i++) {
  await A.p.waitForTimeout(1000)
  link = await A.p.evaluate(() => { const c = document.querySelector('.iq-link'); if (c && !window.__copied) c.click(); return window.__copied || '' })
  if (link) break
  link = await A.p.evaluate(() => {
    for (const el of document.querySelectorAll('a[href], input, textarea, [title], [data-url]')) {
      for (const v of [el.getAttribute('href'), el.value, el.getAttribute('title'), el.getAttribute('data-url'), el.textContent]) { if (v && v.includes('Iz=')) { const m = v.match(/https?:\/\/\S*Iz=[^\s"'<]+/); if (m) return m[0] } }
    }
    const m = document.body.innerText.match(/https?:\/\/\S*Iz=\S+/); return m ? m[0] : ''
  })
}
if (!link) { const m = A.lines.join('\n').match(/https?:\/\/\S*Iz=[^\s"'<]+/); if (m) link = m[0] }
console.log(at() + 'invite link: ' + (link ? link.slice(0, 120) : 'NOT FOUND'))
let ok = !!link
if (link) {
  const u = new URL(link); const inv = `${base}${u.pathname}${u.search}`
  const B = await tab('B')
  await B.p.goto(arm(inv), { waitUntil: 'domcontentloaded' })
  await B.p.waitForTimeout(9000)
  await name_self(B, 'Bo')
  await B.p.waitForTimeout(3000)
  await try_('B: join', () => B.p.locator('.ip-go-join').first().click({ timeout: 8000, force: true }))
  await B.p.waitForTimeout(+afterArg * 1000)
  for (const t of [A, B]) {
    await t.p.screenshot({ path: `${out}.${t.name}.png` })
    fs.writeFileSync(`${out}.${t.name}.txt`, await t.p.evaluate(() => document.body.innerText.replace(/\n{2,}/g, '\n').slice(0, 4000)))
  }
  const sealed = (t) => t.lines.some(l => /sealed|🤝|pier_confirm|friendship/i.test(l))
  const errs = (t) => t.lines.filter(l => /PAGEERROR|is not a function|TypeError|ReferenceError/.test(l))
  for (const t of [A, B]) {
    const open = t.sockets.filter(s => s.open)
    console.log(`${t.name}: sealed=${sealed(t)} errors=${errs(t).length} sockets opened=${t.sockets.length} open now=${open.length} [${open.map(s => s.tag.slice(0, 26) + ' ' + [...s.controls].filter(c => c[0] === '>').join('/')).join(' | ')}] kinds=${[...new Set(open.flatMap(s => [...s.kinds]))].join(',')}`)
    for (const e of errs(t).slice(0, 5)) console.log('   ' + e.slice(0, 200))
    if (!sealed(t) || errs(t).length) ok = false
    if (ONE && open.length !== 1) ok = false
  }
  B.log.end(); B.wsl.end()
}
A.log.end(); A.wsl.end()
await b.close(); proxy.close()
console.log(ok ? 'GOOD' : 'BAD')
process.exit(ok ? 0 : 1)
