// relay_hello.mjs — prove a CLI socket is a cluster flock member before it asks a tab anything.
//
//  The relay refuses `runner_ask` from a socket that has not hello'd with a key in CLUSTER_TRUSTED_PUBS
//   (relay.ts, THE ASK GATE, 2026-10-28) — reaching /relay used to be the only bar, and djamsend's Caddy puts
//    /relay on the internet.  Every CLI that sends runner_ask frames calls `relayHello(ws)` once the socket is
//     open: it signs {control:'hello', from, pub, ts} with this box's claude key (.env.cluster-claude, the
//      same key ghost_compile.ts signs tickets with) and waits for hello_ok.
//  The signed unit is cluster_trust.ts's canonicalHeader (sign dropped, keys sorted) — mirrored here because
//   these scripts run as plain node and cannot import the .ts.
//  No key on this box ⇒ a warning and no hello: against a relay without cluster trust that still works.
import { readFileSync } from 'node:fs'
import * as ed from '@noble/ed25519'

function clusterEnv() {
	const env = { ...process.env }
	for (const f of ['.env.cluster-claude', '.env.cluster-pubs']) {
		try {
			for (const ln of readFileSync(new URL('../' + f, import.meta.url), 'utf8').split('\n')) {
				const m = ln.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
				if (m && env[m[1]] === undefined) env[m[1]] = m[2]
			}
		} catch { /* absent — fall back to process.env */ }
	}
	return env
}

function canonicalHeader(header) {
	const { sign: _drop, ...rest } = header
	const sorted = {}
	for (const k of Object.keys(rest).sort()) sorted[k] = rest[k]
	return JSON.stringify(sorted)
}

// relayHello — resolves { ok, addr?, error? }; never throws, never exits.  `role` picks CLUSTER_IDENTO_<ROLE>_KEY|PUB.
export async function relayHello(ws, { role = 'claude', timeoutMs = 4000 } = {}) {
	const env = clusterEnv()
	const R = role.toUpperCase()
	const key = env[`CLUSTER_IDENTO_${R}_KEY`]
	const pub = env[`CLUSTER_IDENTO_${R}_PUB`]
	if (!key || !pub) {
		console.error(`⚠ relay_hello: no ${role} cluster key on this box — asking unproven (a relay with cluster trust will refuse)`)
		return { ok: false, error: 'no key' }
	}
	const header = { control: 'hello', from: pub.slice(0, 16), pub, ts: Date.now() }
	const sign = ed.etc.bytesToHex(await ed.signAsync(new TextEncoder().encode(canonicalHeader(header)), ed.etc.hexToBytes(key)))
	return await new Promise((resolve) => {
		const done = (v) => { ws.off('message', onMsg); clearTimeout(t); resolve(v) }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.control === 'hello_ok') done({ ok: true, addr: m.addr })
			else if (m.control === 'hello_error') done({ ok: false, error: m.reason })
		}
		const t = setTimeout(() => done({ ok: false, error: `no hello reply in ${timeoutMs}ms` }), timeoutMs)
		ws.on('message', onMsg)
		try { ws.send(JSON.stringify({ ...header, sign })) } catch (e) { done({ ok: false, error: String(e) }) }
	})
}
