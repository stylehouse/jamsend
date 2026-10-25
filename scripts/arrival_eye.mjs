// arrival_eye.mjs — BE A NEWCOMER.  Open a page in headless Chrome, click/type on a schedule, photograph it,
//  keep the body text, every console line, and every relay frame (binary headers decoded).  The instrument
//   that found the late-seal hole (2026-09-11: a friend's music reached 2 arrivals in 5) — see Arrival_todo §top.
//  Usage: node scripts/arrival_eye.mjs <url> <outprefix> [shot-seconds "5,20,45"] [actions]
//   actions: ';'-separated — "<selector>@<sec>" click · "type:<selector>=<text>@<sec>" · "enter:<selector>@<sec>"
//   e.g. node scripts/arrival_eye.mjs 'http://172.17.0.1:9091/BigSoundland?Iz=…' /tmp/x '45' '.bg-listen@8;type:input.ip-name=Kim@14'
//  ARM_SOCKLOG=1 arms the tab so `runner_ask … --player=<prepub>` (minisnap/poke) can look inside it.
//  Outputs: <out>.<sec>s.png/.txt · <out>.console.log · <out>.ws.log.  Needs ~/chromelibs (see runner_eye.mjs).
import { chromium } from 'playwright'
import fs from 'node:fs'; import os from 'node:os'; import net from 'node:net'
const libs = os.homedir() + '/chromelibs/root'
if (fs.existsSync(libs)) { process.env.LD_LIBRARY_PATH = [libs + '/usr/lib/x86_64-linux-gnu', libs + '/lib/x86_64-linux-gnu', process.env.LD_LIBRARY_PATH].filter(Boolean).join(':'); const fc = os.homedir() + '/chromelibs/fonts.conf'; if (fs.existsSync(fc)) process.env.FONTCONFIG_FILE = fc }
const [url, out, ticksArg = '5,20,45,90', clickArg = ''] = process.argv.slice(2)
const ticks = ticksArg.split(',').map(Number)
const clicks = clickArg ? clickArg.split(';').map(c => { const at = c.lastIndexOf('@'); let sel = c.slice(0, at); let text = null; let enter = false; if (sel.startsWith('enter:')) { enter = true; sel = sel.slice(6) } if (sel.startsWith('type:')) { const eq = sel.indexOf('='); text = sel.slice(eq + 1); sel = sel.slice(5, eq) } return { sel, text, enter, sec: +c.slice(at + 1) } }) : []
let target = new URL(url); const [thost, tport] = [target.hostname, +(target.port || 80)]
const proxy = net.createServer(c => { const up = net.connect(tport, thost); c.pipe(up); up.pipe(c); c.on('error', () => up.destroy()); up.on('error', () => c.destroy()) })
// EYE_PORT: a fixed origin, so a PROFILE's storage is found again
await new Promise(r => proxy.listen(+(process.env.EYE_PORT || 0), '127.0.0.1', r)); target.hostname = 'localhost'; target.port = String(proxy.address().port)
// PROFILE=<dir> — a RETURNING visitor: one persistent browser profile across runs (pair with EYE_PORT, same origin)
const launch_args = ['--autoplay-policy=no-user-gesture-required', '--use-fake-ui-for-media-stream']
const ctx_opts = process.env.NOFSA ? { viewport: { width: 412, height: 860 }, isMobile: true, hasTouch: true, userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36' } : { viewport: { width: 1100, height: 800 } }
const b = process.env.PROFILE ? null : await chromium.launch({ args: launch_args })
const ctx = process.env.PROFILE ? await chromium.launchPersistentContext(process.env.PROFILE, { args: launch_args, ...ctx_opts }) : await b.newContext(ctx_opts)
const p = await ctx.newPage()
// NOFSA=1 — be a PHONE: no directory picker (every mobile browser, Brave-by-default), a mobile UA beside it.
if (process.env.NOFSA) await p.addInitScript(() => { try { delete window.showDirectoryPicker; Object.defineProperty(window, 'showDirectoryPicker', { value: undefined, configurable: true }) } catch {} })
// EYE_INIT=<js> — any page-start script (e.g. break a storage API to be a private window)
if (process.env.EYE_INIT) await p.addInitScript(process.env.EYE_INIT)
if (process.env.ARM_SOCKLOG) await p.addInitScript(() => { try { localStorage.setItem('socklog', '1') } catch {} })
const t0 = Date.now(); const log = fs.createWriteStream(out + '.console.log')
p.on('console', m => log.write(((Date.now() - t0) / 1000).toFixed(1) + 's ' + m.text().replace(/\n/g, ' ⏎ ').slice(0, 400) + '\n'))
p.on('pageerror', e => log.write(((Date.now() - t0) / 1000).toFixed(1) + 's PAGEERROR ' + String(e).slice(0, 300) + '\n'))
const wsl = fs.createWriteStream(out + '.ws.log')
p.on('websocket', ws => {
  if (!ws.url().includes('/relay')) return
  const tag = ws.url().split('?')[1] || 'bare'
  const one = (dir) => (f) => { let t = typeof f.payload === 'string' ? f.payload : (() => { const b = f.payload; const nl = b.indexOf(10); const head = nl > 0 ? b.subarray(0, nl).toString('utf8') : ''; try { const j = JSON.parse(head); return '[bin ' + b.length + '] ' + j.type + ' ' + (j.from||'').slice(0,8) + '→' + (j.to||'').slice(0,8) + (j.stream ? ' stream=' + j.stream : '') + (j.bufferid != null ? ' bufferid=' + j.bufferid : '') } catch { return '[bin ' + b.length + '] ' + head.slice(0, 80) } })(); if (t[0] === '{') { try { const j = JSON.parse(t); t = j.control ? 'control:' + j.control + (j.addr ? ' ' + j.addr : '') : (j.header ? j.header.type + ' ' + j.header.from + '→' + j.header.to + (j.swarm && j.swarm.kind ? ' kind=' + j.swarm.kind : '') + (j.swarm && j.swarm.records != null ? ' records=' + j.swarm.records : '') : t.slice(0, 80)) } catch {} } if (/control:log|^ping |^pong |^ack /.test(t)) return; wsl.write(((Date.now() - t0) / 1000).toFixed(1) + 's ' + dir + ' [' + tag.slice(0, 22) + '] ' + t.slice(0, 160) + '\n') }
  ws.on('framereceived', one('<')); ws.on('framesent', one('>'))
})
await p.goto(target.toString(), { waitUntil: 'domcontentloaded' })
const end = Math.max(...ticks, ...clicks.map(c => c.sec)) + 1
const events = [...ticks.map(s => ({ s, kind: 'shot' })), ...clicks.map(c => ({ s: c.sec, kind: c.enter ? 'enter' : (c.text != null ? 'type' : 'click'), sel: c.sel, text: c.text }))].sort((a, b) => a.s - b.s)
for (const ev of events) {
  const wait = ev.s * 1000 - (Date.now() - t0); if (wait > 0) await p.waitForTimeout(wait)
  if (ev.kind === 'shot') { await p.screenshot({ path: `${out}.${ev.s}s.png` }); const txt = await p.evaluate(() => document.body.innerText.replace(/\n{2,}/g, '\n').slice(0, 3000)); fs.writeFileSync(`${out}.${ev.s}s.txt`, txt); console.log(`shot ${ev.s}s`) }
  else if (ev.kind === 'enter') { try { await p.locator(ev.sel).first().press('Enter', { timeout: 3000 }); console.log(`enter ${ev.sel} @${ev.s}s`) } catch (e) { console.log(`enter FAILED ${ev.sel}`) } }
  else if (ev.kind === 'type') { try { await p.locator(ev.sel).first().fill(ev.text, { timeout: 3000 }); await p.locator(ev.sel).first().press('Enter'); console.log(`typed ${ev.sel} @${ev.s}s`) } catch (e) { console.log(`type FAILED ${ev.sel}: ${String(e).split('\n')[0].slice(0, 100)}`) } }
  else { try { await p.locator(ev.sel).first().click({ timeout: 3000, force: true }); console.log(`clicked ${ev.sel} @${ev.s}s`) } catch (e) { console.log(`click FAILED ${ev.sel} @${ev.s}s: ${String(e).split('\n')[0].slice(0, 120)}`) } }
}
await p.waitForTimeout(Math.max(0, end * 1000 - (Date.now() - t0)))
log.end(); wsl.end(); await (b ? b.close() : ctx.close()); proxy.close()
