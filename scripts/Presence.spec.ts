// Presence — prove the batch presence probe end to end: a REAL relay answering a REAL `who`, and the
//  REAL Presence_* ghost verbs (gen/N/Presence.go, Creduler-acquired) absorbing that answer.
//   The two halves are deliberately joined here rather than mocked at the seam: relay-test.ts proves
//    the relay's side of the contract with real sockets, and this proves the ghost's side against the
//     SAME live relay — so the frame shape cannot drift between them while both stay green.
//   What is NOT covered: Tribunal.g's three-line inline dispatch (on_message → w.c.on_who), which needs
//    a browser WebSocket.  It is stubbed here by calling the hook exactly as Tribunal does; if that
//     dispatch is edited, this spec will not notice — say so rather than imply full coverage.
//
//   node_modules/.bin/vitest run -c scripts/Presence.vitest.config.mjs scripts/Presence.spec.ts
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import { createServer } from 'node:http'
import { createRequire } from 'node:module'
import * as ed from '@noble/ed25519'
import Runner from './Story_cli_runner.svelte'
import { attachRelay } from '../src/lib/server/relay'
import { signHeader, prepubOf } from '../src/lib/p2p/cluster_trust'

// This spec boots the machine in JSDOM (Story_cli needs a document), and under that environment vite
//  resolves bare `ws` to its BROWSER shim — whose WebSocketServer is not a constructor.  We need the
//   real Node `ws` on both ends (the relay listens; the peers dial), so reach it through Node's own
//    resolver rather than the bundler's.
const nodeRequire = createRequire(import.meta.url)
const WS = nodeRequire('ws') as typeof import('ws')
const WebSocket = WS.WebSocket

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }
const enhex = ed.etc.bytesToHex
async function mint() {
    const priv = ed.utils.randomPrivateKey()
    const pub = await ed.getPublicKeyAsync(priv)
    return { privHex: enhex(priv), pubHex: enhex(pub) }
}
async function until(pred: () => boolean, ms = 3000): Promise<boolean> {
    const t0 = Date.now()
    while (Date.now() - t0 < ms) { if (pred()) return true; await sleep(20) }
    return pred()
}

// A relay peer that has PROVED its identity (signed hello) — the only kind the relay answers `who` to.
//  Returns a port object shaped like Socket_real's: the one method Presence_ask calls is who().
async function peer(port: number, key: { privHex: string; pubHex: string }, onWho?: (f: any) => void) {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/relay`)
    const ctrl: any[] = []
    await new Promise<void>((r) => ws.on('open', () => r()))
    ws.on('message', (d: any) => {
        const m = JSON.parse(d.toString())
        if (!m.control) return
        ctrl.push(m)
        if ((m.control === 'who_ok' || m.control === 'who_error') && onWho) onWho(m)
    })
    const addr = prepubOf(key.pubHex)
    const ts = Date.now()
    const sign = await signHeader({ control: 'hello', from: addr, pub: key.pubHex, ts }, key.privHex)
    ws.send(JSON.stringify({ control: 'hello', from: addr, pub: key.pubHex, ts, sign }))
    await until(() => ctrl.some((m) => m.control === 'hello_ok'))
    // the port seam: exactly Socket_real's `who`, minus the browser WebSocket
    const p = { type: 'websocket', real: 1, who(addrs: string[], corr: string) { ws.send(JSON.stringify({ control: 'who', addrs, corr })) } }
    return { ws, ctrl, addr, port: p }
}

test('Presence: a real relay answers `who`, and the ghost absorbs it three-valued', async () => {
    let H: any
    mount(Runner, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 40 && !(H && typeof H.Creduler_ensure === 'function'); i++) await sleep(50)
    expect(typeof H?.Creduler_ensure, 'Lies ghost deposited (shell booted)').toBe('function')

    const liesW = H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })
    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }
    for (let t = 0; t < 160 && typeof H.Presence_ask !== 'function'; t++) {
        for (const h of allHouses(H)) if (!h.started) h.started = true
        try { await H.Creduler_ensure(liesW) } catch {}
        flushSync()
        for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain(); flushSync()
        await sleep(60)
    }
    expect(typeof H.Presence_ask, 'Presence ghost acquired (gen/N/Presence.go)').toBe('function')

    // ── INERT WITHOUT A RELAY — the property every Book depends on ───────────────────────────────
    //  A Story runs on the mock carrier, whose port has no `who` (it is a relay control frame).  If
    //   presence could mint a %Presence particle or suppress a send there, it would change the snap
    //    of every Book that stands a Swarm up — i.e. it would re-dige fixtures across the repo.  It
    //     must do NOTHING at all: no particle, no suppression, no throw.
    const bookW = H.i({ A: 'PresenceBook' }).i({ w: 'PresenceBook' })
    const mockT = bookW.oai({ transport: 1, type: 'websocket' }); mockT.c.up = bookW
    mockT.c.port = { type: 'websocket', send() {}, recv() {} }        // a mock port: no who()
    expect(H.Presence_port(bookW), 'a port without who() is not a presence port').toBe(null)
    expect(H.Presence_ask(bookW, ['aaaa', 'bbbb']), 'asking without a relay asks nothing').toBe(0)
    expect(bookW.o({ Presence: 1 }).length, 'and mints NO %Presence particle — the snap is untouched').toBe(0)
    expect(H.Presence_worth_sending(bookW, 'aaaa'), 'so every send proceeds exactly as before').toBe(true)

    // ── a real relay, and three real identities on it ────────────────────────────────────────────
    const srv = createServer()
    const relayPort: number = await new Promise((r) => srv.listen(0, '127.0.0.1', () => r((srv.address() as any).port)))
    const relay = attachRelay(srv)

    const meKey = await mint(), aKey = await mint(), bKey = await mint()
    const gone = prepubOf((await mint()).pubHex)   // a friend who never connects — the honest offline case

    // our own world, wearing the carrier port exactly where Socket_real parks it
    const w = H.i({ A: 'Presence' }).i({ w: 'Presence' })
    const me = await peer(relayPort, meKey, (f) => H.Presence_take(w, f))   // ← Tribunal's inline dispatch, stubbed
    const A = await peer(relayPort, aKey)
    const B = await peer(relayPort, bKey)
    const t = w.oai({ transport: 1, type: 'websocket' }); t.c.up = w; t.c.port = me.port

    // ── before any ask: UNKNOWN, never false.  This is the boot-time starvation guard. ───────────
    expect(H.Presence_live(w, A.addr), 'unasked reads null (unknown), NOT false').toBe(null)
    expect(H.Presence_fresh(w), 'unasked is not fresh').toBe(false)
    expect(H.Presence_online(w), 'unasked online list is empty').toEqual([])
    expect(H.Presence_note(w), 'unasked says so in words').toBe('presence never asked')

    // ── one frame asks about the whole roster ────────────────────────────────────────────────────
    H.Presence_arm(w)
    const asked = H.Presence_ask(w, [A.addr, B.addr, gone])
    expect(asked, 'asked all three in ONE frame').toBe(3)
    expect(await until(() => H.Presence_fresh(w)), 'answer came back').toBe(true)

    expect(H.Presence_live(w, A.addr), 'A is online (verified hello bind)').toBe(true)
    expect(H.Presence_live(w, B.addr), 'B is online').toBe(true)
    expect(H.Presence_live(w, gone), 'a never-connected friend is FALSE, not null — this is a real answer').toBe(false)
    expect(H.Presence_online(w).sort(), 'the roster view lists exactly the live two').toEqual([A.addr, B.addr].sort())

    // the answer is legible as particles, not just a cached array
    const p = w.o({ Presence: 1 })[0]
    expect(p, '%Presence particle exists').toBeTruthy()
    expect(p.o({ Seen: 1 }).length, 'one %Seen per online friend').toBe(2)
    expect(p.o({ Seen: 1, pub: A.addr }).length, '%Seen,pub:<A> is findable by query').toBe(1)
    // wall clock must NOT be in sc — a Date.now() there re-digests every pass and reddens any Book
    expect(JSON.stringify(p.sc), 'no wall clock in sc (dige stability)').not.toMatch(/17[0-9]{11}/)

    // ── B leaves: the next answer REPLACES the set, it does not accumulate ───────────────────────
    B.ws.close()
    await until(() => relay.localCount >= 0 && false, 250)   // let the relay's close handler unbind
    H.Presence_ask(w, [A.addr, B.addr, gone])
    expect(await until(() => H.Presence_live(w, B.addr) === false), 'B went offline in the next answer').toBe(true)
    expect(H.Presence_live(w, A.addr), 'A still online').toBe(true)
    expect(w.o({ Presence: 1 })[0].o({ Seen: 1 }).length, 'the %Seen set SHRANK — snapshot, not accumulation').toBe(1)

    // ── the send gate: ONLY a fresh positive "not there" suppresses a frame ──────────────────────
    //  This asymmetry is what makes it safe to put in the heartbeat — wiring it in can remove frames
    //   we already knew were pointless, and can never strand a friend because presence was unavailable.
    expect(H.Presence_worth_sending(w, A.addr), 'send to a friend the relay says is online').toBe(true)
    expect(H.Presence_worth_sending(w, gone), 'do NOT send to a friend the relay says is offline').toBe(false)
    const fresh = H.i({ A: 'PresenceB' }).i({ w: 'PresenceB' })   // a world that has never asked
    expect(H.Presence_live(fresh, A.addr), 'never-asked world knows nothing').toBe(null)
    expect(H.Presence_worth_sending(fresh, A.addr), 'UNKNOWN still sends — no presence, no change in behaviour').toBe(true)

    // ── staleness degrades to UNKNOWN, never to offline ──────────────────────────────────────────
    //  Read with a tiny window to simulate an answer that has aged out, without waiting 30s.
    expect(H.Presence_fresh(w, 1), 'a 1ms window makes the answer stale').toBe(false)
    const pp = w.o({ Presence: 1 })[0]
    const realAt = pp.c.answered_at
    pp.c.answered_at = realAt - 60000          // age the answer past the 30s default
    expect(H.Presence_live(w, A.addr), 'a stale answer is UNKNOWN, not offline').toBe(null)
    expect(H.Presence_online(w), 'a stale roster reads empty rather than lying').toEqual([])
    expect(H.Presence_note(w), 'and it says STALE in words').toMatch(/STALE/)
    expect(H.Presence_worth_sending(w, gone), 'a stale answer must NOT keep suppressing sends').toBe(true)
    pp.c.answered_at = realAt

    // ── the roster ask: ONE frame for the whole friend list, our own pub excluded ────────────────
    //  The roster is the real thing — %Pier children of the identity's %Peering, Swarm.g's canonical
    //   walk — so this exercises Presence_ask_roster's actual path, not a stand-in for it.
    const ident = w.oai({ Identity: 1 }); ident.c.up = w; ident.sc.prepub = me.addr
    const peering = ident.oai({ Peering: 1, name: me.addr }); peering.c.up = ident
    for (const pub of [A.addr, B.addr, gone, me.addr]) peering.oai({ Pier: 1, pub }).c.up = peering
    const n = H.Presence_ask_roster(w, ident)
    expect(n, 'asked the three FRIENDS in one frame — our own pub excluded').toBe(3)
    expect(await until(() => H.Presence_online(w).length === 1), 'the roster answer came back').toBe(true)
    expect(H.Presence_online(w), 'only A is still up').toEqual([A.addr])
    expect(H.Presence_worth_sending(w, A.addr), 'A is worth a pulse').toBe(true)
    expect(H.Presence_worth_sending(w, B.addr), 'B is not — one frame saved').toBe(false)
    expect(H.Presence_worth_sending(w, gone), 'nor is the friend who never connected').toBe(false)
    expect(H.Presence_note(w), 'the note reads as a sentence').toMatch(/^1\/3 online, \d+s ago$/)

    // ── the leak gate: an unverified socket is refused, and the refusal is RECORDED not silent ───
    const nobody = new WebSocket(`ws://127.0.0.1:${relayPort}/relay?addr=sneaky`)
    await new Promise<void>((r) => nobody.on('open', () => r()))
    const nobodyCtrl: any[] = []
    nobody.on('message', (d: any) => nobodyCtrl.push(JSON.parse(d.toString())))
    nobody.send(JSON.stringify({ control: 'who', addrs: [A.addr], corr: 'x' }))
    expect(await until(() => nobodyCtrl.some((m) => m.control === 'who_error')), 'relay refuses who from a non-hello-bound socket').toBe(true)
    expect(nobodyCtrl.some((m) => m.control === 'who_ok'), 'and never leaks an answer to it').toBe(false)

    // the ghost's own handling of a refusal: recorded, and presence falls back to UNKNOWN
    H.Presence_take(w, { control: 'who_error', reason: 'not hello-bound' })
    expect(H.Presence_note(w), 'a refusal is stated, not swallowed').toMatch(/refused/)

    nobody.close(); me.ws.close(); A.ws.close()
    relay.close(); srv.close()
    await sleep(50)
})
