// scripts/runner_ask.mjs — "ask the LIVE browser runner to RUN a Story Book, or EXAMINE its state."
//
//  The real-time / real-audio twin of the headless CredRunner.  CredRunner boots the whole machine in
//   node (jsdom, no Web Audio, deterministic tick-snaps); THIS instead talks to a runner ALREADY running
//    in a real browser on :9091 (booted with ?B=<Book>), over the SAME /relay websocket the editor uses,
//     and the runner answers with live verdicts/snaps — real wall clock, real AudioContext, muted.
//  Addr-less request/reply correlated BY CORR, exactly like scripts/ghost_compile.ts (which targets the
//   editor); this one targets the runner.  The relay (src/lib/server/relay.ts) remembers this socket by
//    corr and routes the runner's {control:'runner_ack'} reply straight back here.  Handler is
//     Lies_runner_ask_recv (LiesFunk.svelte), registered on('runner_ask') in LiesLies.svelte.
//
//  Usage:
//    node scripts/runner_ask.mjs ping                    # liveness {role,channel,running}
//    node scripts/runner_ask.mjs run MusuLive            # kick a run (returns immediately)
//    node scripts/runner_ask.mjs run MusuLive --watch    # kick + poll state until done|failed
//    node scripts/runner_ask.mjs runners                 # list the Waft:Cluster registry (prepub  ★fav)
//    node scripts/runner_ask.mjs run MusuLive --runner=49dee9   # court ONE runner by prepub|prefix and
//                                                          #  INSIST: retry IT on busy/silence (never failover);
//                                                           #   no --runner ⇒ AUTO-COURT: ping the flock, pin ONE
//                                                            #    (our-lease ▸ free ▸ first ack) — never the raw
//                                                             #     role broadcast that double-dispatched a run
//                                                              #      onto every open runner tab
//    node scripts/runner_ask.mjs state [--watch]         # verdict + phase/n/total
//    node scripts/runner_ask.mjs steps                   # per-Step ok/caveat/dige
//    node scripts/runner_ask.mjs snap 3                  # one Step's got_snap (the live world serialisation)
//    node scripts/runner_ask.mjs rungos                  # the held runs, each addressable by uid
//    node scripts/runner_ask.mjs snap 3 @ab12cd34        # a HELD run's frozen pin (the runner hangs in there)
//    node scripts/runner_ask.mjs accept                  # RE-RECORD: accept the live run's steps as the new
//                                                          #  fixture (the Accept-All button, over the wire) —
//                                                           #   the only sanctioned re-record path (never headless)
//    node scripts/runner_ask.mjs release                 # hang up: drop our engagement lease + GC the runs,
//                                                          #  tearing the runner's Story world down to H:Mundo (idle)
//    node scripts/runner_ask.mjs socklog [on|off] [--reload]  # arm the tab's trace-ring disk dump (the 🪪 hatch
//                                                          #  toggle, remotely); --reload re-boots it so the
//                                                           #   socket tap also lands (the ring dump needs no reload)
//    node scripts/runner_ask.mjs dump                    # force an immediate trace dump (skip the ~5s throttle),
//                                                          #  so tracelog.mjs reads NOW, not up-to-5s-ago
//    node scripts/runner_ask.mjs poke Radio_skip         # fire an ALLOWLISTED UI verb on the live tab (the
//                                                          #  runner-side allowlist is the authority; see
//                                                           #   Lies_runner_ask_recv op:'poke')
//
//  ENGAGEMENT: `run` takes a soft 10-min lease on the runner, keyed by this CLI's stable client id (the
//   claude cluster prepub from .env.cluster-claude, or RUNNER_CLIENT).  A second client is refused while the
//    lease is live ("don't run into each other's runners"); the same client re-attaches.  ping/state report
//     the lease + favourite_client.  After a `release` (or 10-min idle timeout), `@uid` on a reaped run says
//      it was garbage-collected, not a bare miss.
//
//  RUNNER_URL overrides the relay origin (default http://172.17.0.1:9091 — the runner dev server as seen
//   from the claude container; use http://localhost:9091 if running on the host).  Exit 1 when a --watch
//    run finishes red (outcome not ok) or the request errors, else 0 — so it scripts.
import { WebSocket } from 'ws'
import { readFileSync, writeFileSync } from 'node:fs'
// the SHARED liveness thresholds + verdict — the same numbers the ghost (LiesLies.svelte) reads,
//  so the CLI can no longer drift to a worse death criterion than the layer it's questioning.
import { DEAD_MS, SLUGGISH_MS, liveness } from '../src/lib/O/runner_liveness.mjs'

const OPS = ['ping', 'probe', 'world', 'run', 'state', 'steps', 'snap', 'trace', 'assertions', 'declare', 'rungos', 'accept', 'release', 'runners', 'reload', 'socklog', 'dump', 'poke']

// ── court a runner via Waft:Cluster ──────────────────────────────────────────────────────────
//  deLines the registry snap (wormhole/Cluster/toc.snap — the durable HostedIdentity directory the editor
//   builds from advertise beacons) so we can address ONE runner BY PREPUB (to:<prepub>) instead of the role
//    broadcast to:'runner' that fans to EVERY runner.  No eatfunc to import here (Lies_dispatch_target is
//     ghost-swallowed) and we don't need full deWaft — just the flat indent+comma lines:
//      `HostedIdentity:<prepub>,role:runner`.  (Editor-side the auto-allocator tries-another-if-busy;
//       the CLI does the OPPOSITE — it INSISTS on the one runner you name, for repeatable targeted testing.)
function clusterRunners() {
	let txt
	try { txt = readFileSync(new URL('../wormhole/Cluster/toc.snap', import.meta.url), 'utf8') } catch { return [] }
	const out = []
	for (const raw of txt.split('\n')) {
		const line = raw.trim()
		if (!line.startsWith('HostedIdentity:')) continue
		const parts = line.split(',')
		const pub = parts[0].slice('HostedIdentity:'.length)
		const props = {}
		for (const p of parts.slice(1)) { const i = p.indexOf(':'); if (i > 0) props[p.slice(0, i)] = p.slice(i + 1) }
		// role:'player' is a diagnostic-armed END-USER room (a Sounditron — someone's actual music page).
		//  It is deliberately NOT a runner: it must never receive a dispatched Book, so it is excluded
		//   here by default exactly as it is excluded from the editor's allocator.  But it IS addressable,
		//    which is the whole point of giving it a row — ping/state/dump/poke/reload on the only tabs
		//     that reproduce the live bugs.  Opt in per-call with an explicit --player=<id>; there is no
		//      "latest player" convenience and no bare --player, because picking someone's music tab by
		//       accident is precisely the mistake this shape exists to prevent.
		if (props.role === 'runner') out.push({ pub, favourite_client: props.favourite_client })
		if (props.role === 'player') players.push({ pub })
	}
	return out
}
const players = []
// resolve --runner <id> (exact prepub ▸ prefix) to a prepub; no id ⇒ the LATEST runner in the directory.
function resolveRunner(id) {
	const rs = clusterRunners()
	if (!id) return rs[rs.length - 1]?.pub
	return (rs.find(r => r.pub === id) ?? rs.find(r => r.pub.startsWith(id)))?.pub
}
// resolve --player <id> — EXPLICIT ONLY (no bare form, no latest-fallback): an id must be given and must
//  match a role:'player' row.  Never falls back to a runner, so a typo fails loudly instead of quietly
//   aiming at the wrong tab.
function resolvePlayer(id) {
	clusterRunners()                       // populates `players` as a side effect of the one parse
	if (!id) return undefined
	return (players.find(p => p.pub === id) ?? players.find(p => p.pub.startsWith(id)))?.pub
}
// bookNeedsAC — read the Credence board (wormhole/Credence/toc.snap) for a Book's Storying cell, flat-line
//  parsed like clusterRunners: `Funkcion:Storying,of_Book:<book>,…,needAC:1`.  So the CLI passes needAC for
//   you EVEN IF you never read Credence → the runner secures AudioContext pre-run and the --watch below
//    narrates the wait + the grant, instead of an audio step popping mid-run or the run silently blocking.
function bookNeedsAC(book) {
	if (!book) return false
	let txt
	try { txt = readFileSync(new URL('../wormhole/Credence/toc.snap', import.meta.url), 'utf8') } catch { return false }
	for (const raw of txt.split('\n')) {
		const line = raw.trim()
		if (!line.startsWith('Funkcion:Storying')) continue
		const parts = line.split(',')
		if (parts.includes(`of_Book:${book}`) && parts.includes('needAC:1')) return true
	}
	return false
}

// bookNeedsFSA — the needsFSA twin of bookNeedsAC: `Funkcion:Storying,of_Book:<book>,…,needsFSA:1`.  So the
//  CLI carries needsFSA even if you never read Credence → the editor routes the run to an fsa-live runner and
//   a proxy-only runner refuses it (a disk-heavy Book must not crawl every read through the remoteWormhole hop).
function bookNeedsFSA(book) {
	if (!book) return false
	let txt
	try { txt = readFileSync(new URL('../wormhole/Credence/toc.snap', import.meta.url), 'utf8') } catch { return false }
	for (const raw of txt.split('\n')) {
		const line = raw.trim()
		if (!line.startsWith('Funkcion:Storying')) continue
		const parts = line.split(',')
		if (parts.includes(`of_Book:${book}`) && parts.includes('needsFSA:1')) return true
	}
	return false
}
const argv  = process.argv.slice(2)
const flags = new Set(argv.filter(a => a.startsWith('--') && !a.startsWith('--runner=')))
const uidTok = argv.find(a => a.startsWith('@'))             // @uid → target a HELD run's frozen pins
const uid    = uidTok ? uidTok.slice(1) : undefined
const runnerSel = (argv.find(a => a.startsWith('--runner=')) ?? '').split('=')[1]   // --runner=<prepub|prefix>
const playerSel = (argv.find(a => a.startsWith('--player=')) ?? '').split('=')[1]   // --player=<prepub|prefix> — a Sounditron
const pos   = argv.filter(a => !a.startsWith('-') && !a.startsWith('@'))
const op    = pos[0]
const arg   = pos[1]
const watch = flags.has('--watch')
if (!op || !OPS.includes(op)) {
	console.error('usage: node scripts/runner_ask.mjs <ping|probe|run <Book>|state|steps|snap <n>|assertions|declare \'<sentence>\'|rungos|accept|release|runners|reload|socklog [on|off] [--reload]|dump|poke <verb>> [@uid] [--runner=<id>] [--watch]')
	process.exit(2)
}
// `runners` — list the Waft:Cluster registry, PROVED (2026-08-09, the owner chasing a dead ★claude row:
//  "--runner=49dee91d61a9de64 is long gone, are we not culling old hosts from Cluster?").  The registry
//   is durable BY DESIGN — Lies_runner_roster's GC (LiesLies.svelte ~1713) reaps only ANONYMOUS silent
//    rows after LIVE_MS; a FAVOURITED runner is remembered forever ("that relationship is the whole
//     reason to remember it durably"), so this list can and will hold the long-dead, and nothing in the
//      snap says which.  So prove it here: one read-only role-broadcast ping, mark who answered.  Relay
//       down ⇒ the plain cold listing, labelled as such (the old behaviour, minus the false confidence).
//  Self-contained on purpose: the shared ws/collectAcks machinery is declared BELOW this early-exit
//   branch (TDZ), and a listing must not court, stash a sticky, or touch anyone's lease — the ping here
//    carries no `client`, so Lies_engage_touch sees only the ephemeral addr.
if (op === 'runners') {
	const rs = clusterRunners()
	if (!rs.length) { console.error('no runners in wormhole/Cluster/toc.snap (none advertised yet, or the editor never wrote it)'); process.exit(1) }
	let alive = null   // null ⇒ relay unreachable (liveness unknown); else the Set of prepubs that acked
	try {
		const url  = (process.env.RUNNER_URL || 'http://172.17.0.1:9091').replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
		const addr = `runcli-${Date.now()}-ls`
		const w2   = new WebSocket(`${url}?addr=${encodeURIComponent(addr)}`)
		const up   = await new Promise((res) => { const t = setTimeout(() => res(false), 3000); w2.on('open', () => { clearTimeout(t); res(true) }); w2.on('error', () => { clearTimeout(t); res(false) }) })
		if (up) {
			// ADDRESSED pings, one per registry row, in parallel — NOT a role broadcast: the court's own
			//  comment has the receipt ("the role broadcast reaches whichever single socket the relay
			//   favours, so it can NOT be trusted to find a *specific* runner"), and the first cut of this
			//    probe proved it — a runner that had just run a whole sweep listed ✗ on one call and ✓ on
			//     the next.  A census must ask each row by name.
			const got = new Set()
			const pingOne = (pub) => new Promise((res) => {
				const corr = `ra-ls-${Date.now()}-${pub.slice(0, 6)}`
				const onMsg = (d) => {
					let m; try { m = JSON.parse(String(d)) } catch { return }
					if (m.corr !== corr) return
					if (m.control === 'runner_ack') got.add(pub)
					w2.off('message', onMsg); clearTimeout(t); res()
				}
				const t = setTimeout(() => { w2.off('message', onMsg); res() }, 4000)
				w2.on('message', onMsg)
				w2.send(JSON.stringify({ header: { type: 'runner_ask', from: addr, to: pub, seq: Date.now(), corr }, ask: { op: 'ping' }, corr }))
			})
			await Promise.all([...rs.map(r => pingOne(r.pub)), ...players.map(p => pingOne(p.pub))])
			alive = got
			w2.close()
		}
	} catch { /* relay unreachable — cold listing below */ }
	const mark = (pub) => alive == null ? '' : (alive.has(pub) ? '  ✓ live' : '  ✗ not answering')
	for (const r of rs) console.log(`${r.pub}${r.favourite_client ? `  ★${r.favourite_client.slice(0, 8)}` : ''}${mark(r.pub)}`)
	for (const p of players) console.log(`${p.pub}  ♪player (someone's music page — --player= to address)${alive != null && alive.has(p.pub) ? '  ✓ live' : ''}`)
	if (alive == null) console.error('⚠ relay unreachable — cold registry listing, liveness unknown')
	else {
		const dead = rs.filter(r => !alive.has(r.pub))
		if (dead.length) console.error(`⇢ ${dead.length} registry row(s) not answering — a FAVOURITED row is never auto-culled (Lies_runner_roster keeps it durably); un-favour it and the 45s GC takes it on the next roster pass`)
	}
	process.exit(0)
}
// TARGET — who to address.  --runner=<id> courts ONE runner by prepub (insist, no failover); else 'runner'
//  is a PLACEHOLDER the auto-court below (post-connect) resolves to one prepub — the raw role broadcast
//   never carries a real ask any more (the relay fans it to every tab: the double-dispatch bug).
let TARGET = 'runner'
if (runnerSel !== undefined) {
	const pub = resolveRunner(runnerSel)
	if (!pub) { console.error(`✗ --runner=${runnerSel || '(latest)'}: no matching runner in wormhole/Cluster/toc.snap — try \`runners\``); process.exit(2) }
	TARGET = pub
}
// --player=<id> — address a Sounditron (role:'player').  READ-ONLY VERBS ONLY, refused loudly otherwise:
//  a player is someone's actual music page, and `run` would put a Book on it (the whole thing the role
//   split exists to prevent) while accept/release/declare are run-lifecycle verbs that presuppose one.
//    `reload` IS allowed — it is the one mutating verb with a real diagnostic purpose (reproduce a
//     one-sided reload) and it costs the human a moment of music, not a hijacked tab.
if (playerSel !== undefined) {
	if (runnerSel !== undefined) { console.error('✗ pass --runner= or --player=, not both'); process.exit(2) }
	const PLAYER_OPS = ['ping', 'probe', 'world', 'state', 'rungos', 'runners', 'socklog', 'dump', 'poke', 'reload', 'snap', 'steps', 'assertions']
	if (!PLAYER_OPS.includes(op)) { console.error(`✗ '${op}' is not allowed on a --player (someone's music page). Allowed: ${PLAYER_OPS.join(' ')}`); process.exit(2) }
	const pub = resolvePlayer(playerSel)
	if (!pub) { console.error(`✗ --player=${playerSel || '(none given)'}: no matching role:'player' row in wormhole/Cluster/toc.snap — try \`runners\``); process.exit(2) }
	TARGET = pub
}
if (op === 'run' && !arg)  { console.error('run needs a Book: node scripts/runner_ask.mjs run <Book>'); process.exit(2) }
if (op === 'poke' && !arg) { console.error('poke needs a verb: node scripts/runner_ask.mjs poke <Radio_toggle|Radio_skip|Radio_source_toggle|Sounditron_diag_toggle> [--runner=<id>]'); process.exit(2) }
if (op === 'socklog' && arg && arg !== 'on' && arg !== 'off') { console.error('socklog takes on|off (default on): node scripts/runner_ask.mjs socklog [on|off] [--reload] [--runner=<id>]'); process.exit(2) }
if (op === 'declare' && !arg) { console.error('declare needs the sworn sentence (quote it — byte-identical to `assertions` output): node scripts/runner_ask.mjs declare \'<sentence>\''); process.exit(2) }
if (op === 'snap' && !arg) { console.error('snap needs a step number: node scripts/runner_ask.mjs snap <n>'); process.exit(2) }
if (op === 'trace' && !arg) { console.error('trace needs a step number: node scripts/runner_ask.mjs trace <n>  (the step\'s beliefs-cycle trace + causal|timeout quiescent label)'); process.exit(2) }

// clientId — the stable identity the runner records as the engagement holder (its don't-steal lease).
//  Prefer the claude cluster prepub (.env.cluster-claude → CLUSTER_IDENTO_CLAUDE_PUB, first 16 hex) so the
//   lease is STABLE across invocations — the runner can tell "was it you?" and let us re-attach to our own
//    held runner instead of refusing.  Override with RUNNER_CLIENT; fall back to a fixed tag if no key.
function clientId() {
	if (process.env.RUNNER_CLIENT) return process.env.RUNNER_CLIENT
	try {
		const env = readFileSync(new URL('../.env.cluster-claude', import.meta.url), 'utf8')
		const m = env.match(/CLUSTER_IDENTO_CLAUDE_PUB=([0-9a-fA-F]{16,})/)
		if (m) return m[1].slice(0, 16)
	} catch { /* no key file — fall through */ }
	return 'claude-cli'
}
const CLIENT = clientId()

const ask = { op, client: CLIENT }
if (op === 'run')  { ask.book = arg; if (bookNeedsAC(arg)) ask.needAC = 1; if (bookNeedsFSA(arg)) ask.needsFSA = 1 }   // Credence-read → runner secures AC / routes to an FSA runner pre-run
if (op === 'snap' || op === 'trace') ask.n = Number(arg)
if (op === 'declare') ask.sentence = arg   // the explorer button's CLI twin (e_story_declare)
if (op === 'socklog') { ask.on = arg === 'off' ? 0 : 1; if (flags.has('--reload')) ask.reload = 1 }   // arm the tab's trace dump remotely (was: 🪪 hatch only)
if (op === 'poke') ask.verb = arg          // allowlisted UI verb (runner-side allowlist is the authority)
if (uid) ask.uid = uid

const HTTP       = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL     = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
// a single request waits just PAST sluggish before giving up — the old 8s was BELOW sluggish
//  (9s), so a busy-but-alive tab read as no-reply.  The `--watch` loop below then budgets a whole
//   DEAD_MS of accumulated silence (across polls) before it calls the runner dead.
const TIMEOUT_MS = Number(process.env.RUNNER_ASK_TIMEOUT_MS || (SLUGGISH_MS + 3000))
const WATCH_MS   = Number(process.env.RUNNER_WATCH_MS || 120000)
const stamp      = Date.now()
const cliAddr    = `runcli-${stamp}`   // ephemeral addr — relay LOGS the connect/disconnect; reply is corr-routed

let corrSeq = 0
// sendAsk — one runner_ask, settled on the FIRST of: a corr-matched runner_ack, a relay `undeliverable`
//  (no runner on the relay), or a timeout (a half-open runner leaves the relay falsely "delivering" and
//   never acks — silence-past-N is the only thing that catches it).
function sendAsk(ws, theAsk, to = undefined, timeoutMs = TIMEOUT_MS) {
	const corr = `ra-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		let done = false
		const settle = (v) => { if (!done) { done = true; ws.off('message', onMsg); clearTimeout(timer); resolve(v) } }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.corr !== corr) return                                  // relay control:log + other corrs — ignore
			if (m.control === 'undeliverable') settle({ ok: false, error: 'no runner connected to the relay (frame dropped)' })
			else if (m.control === 'runner_ack') settle(m)
		}
		const timer = setTimeout(() => settle({ ok: false, error: `no reply in ${Math.round(timeoutMs / 1000)}s (runner not connected or half-open?)` }), timeoutMs)
		ws.on('message', onMsg)
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: to ?? TARGET, seq: Date.now(), corr }, ask: theAsk, corr }))
	})
}
// collectAcks — the courting probe: ONE role-broadcast ping, but instead of settling on the first ack it
//  gathers EVERY runner's ack (each carries {self, engagement}) for a short grace after the first, so the
//   CLI can SEE the whole flock and then address one runner by prepub.  A read-only ping fanning to every
//    tab is harmless; a `run` fanning is the double-dispatch bug this exists to prevent.
function collectAcks(ws, theAsk, graceMs = 900) {
	const corr = `ra-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		const acks = []
		let grace = null
		const finish = () => { ws.off('message', onMsg); clearTimeout(first); clearTimeout(grace); resolve(acks) }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.corr !== corr) return
			if (m.control === 'undeliverable') return finish()               // no runner on the relay at all
			if (m.control !== 'runner_ack') return
			acks.push(m)
			if (!grace) { clearTimeout(first); grace = setTimeout(finish, graceMs) }
		}
		const first = setTimeout(finish, TIMEOUT_MS)
		ws.on('message', onMsg)
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: 'runner', seq: Date.now(), corr }, ask: theAsk, corr }))
	})
}

const ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(cliAddr)}`)
ws.on('error', (e) => { console.error(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`); process.exit(1) })
const opened = await new Promise((resolve) => { const wd = setTimeout(() => resolve(false), 5000); ws.on('open', () => { clearTimeout(wd); resolve(true) }) })
if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up and ?B= a runner booted?`); process.exit(1) }

// COURT — no --runner given ⇒ pick ONE runner before the real ask ever leaves.  The old default addressed
//  to:'runner' for everything, and the relay FANS a role frame to every runner tab — so with two tabs up a
//   `run` dispatched to BOTH (two rungos of the same Book racing) and every state/steps poll flip-flopped
//    between whichever tab acked first.  Now: one broadcast PING, collect every ack, then choose —
//     STICKY (the prepub the last invocation courted, /tmp stash — so `steps` lands on the runner `run`
//      used, even when a broadcast-era double-stamp left OUR lease on several tabs) ▸ the runner holding
//       our lease ▸ for `run` a free one ▸ first to ack — and pin TARGET to its prepub for this whole
//        invocation (`run --watch` polls included).
const STICKY_PATH = '/tmp/runner_ask.target'
const eng    = (a) => a.result?.engagement
const isMine = (a) => eng(a)?.client === CLIENT && eng(a)?.status === 'active' && !eng(a)?.stale
const isFree = (a) => { const e = eng(a); return !e || e.status !== 'active' || e.stale || e.client === CLIENT }
// A PLAYER IS NOT A RUNNER, WHATEVER ANSWERED (the owner 2026-08-09: *"can you fix that script to not
//  ask role=player to run tests for you"*).  The court addresses the ROLE `runner` and then trusts
//   whoever acks — but relay `bind()` is ADDITIVE fan-out (one per-addr Set, any claimant
//    shadow-subscribes), so a tab that is really someone's music page can answer a runner broadcast.
//     `--player=` was built to keep those tabs read-only and it does its job; this is the OTHER door,
//      the one nobody passes a flag to, and it was wide open.
//  The ack already carries the answer — `ping` returns `{role}` — so this is not a new fact to plumb,
//   only one that was never read.  Filter on it, and DO NOT fall back to a player when no runner
//    answers: silence is the correct outcome there.  Putting a Book on a listener's page is not a
//     degraded success, it is the failure the whole role split exists to prevent.
const isRunner = (a) => a.result?.role === 'runner'
if (TARGET === 'runner') {
	// 1. STICKY — the prepub the last invocation used (/tmp stash).  Pinged DIRECTLY: the role broadcast
	//    reaches whichever single socket the relay favours, so it can NOT be trusted to find a *specific*
	//     runner — only an addressed frame can.  A busy-with-someone-else sticky is skipped for `run`.
	let sticky = null
	try { sticky = readFileSync(STICKY_PATH, 'utf8').trim() || null } catch { /* no stash yet */ }
	if (sticky) {
		const a = await sendAsk(ws, { op: 'ping', client: CLIENT }, sticky, 4000)
		// role-checked too: a stale stash can name a tab that has since been re-booted as a player.
		if (a.control === 'runner_ack' && isRunner(a) && (op !== 'run' || isFree(a))) TARGET = sticky
	}
	// 2. no (usable) sticky — broadcast-court: one role ping, gather the acks, pick
	//     our-lease ▸ (run) free ▸ first.
	if (TARGET === 'runner') {
		const allAcks = await collectAcks(ws, { op: 'ping', client: CLIENT })
		const acks = allAcks.filter(isRunner)
		const shooed = allAcks.length - acks.length
		if (shooed > 0) console.error(`⇢ ignoring ${shooed} non-runner tab${shooed === 1 ? '' : 's'} that answered the runner broadcast (role≠runner — someone's music page)`)
		if (!acks.length && allAcks.length) {
			console.error(`✗ no role:'runner' tab answered — only ${allAcks.length} player/other tab${allAcks.length === 1 ? '' : 's'} did.  Boot a runner (?B=<Book>); refusing to put a Book on a listener's page.`)
			process.exit(3)
		}
		const pick = acks.find(isMine) ?? (op === 'run' ? (acks.find(isFree) ?? acks[0]) : acks[0])
		if (pick?.result?.self) {
			TARGET = pick.result.self
			if (acks.length > 1) console.error(`⇢ ${acks.length} runners acked — courting ${TARGET.slice(0, 8)}${isMine(pick) ? ' (holds our lease)' : ''}; the rest stay untouched`)
		}
	}
	// still 'runner' ⇒ zero acks — let the real ask surface the usual no-reply/undeliverable error
}
if (TARGET !== 'runner') { try { writeFileSync(STICKY_PATH, TARGET + '\n') } catch { /* stash is best-effort */ } }

let exitCode = 0
// INSIST: when courting a named runner (--runner=), DON'T failover — retry the SAME target on a busy refusal
//  or silence (an occupied or half-open runner), up to RUNNER_INSIST_TRIES.  The role broadcast stays single-shot.
const INSIST = runnerSel !== undefined ? Number(process.env.RUNNER_INSIST_TRIES || 5) : 1
let reply
for (let attempt = 1; ; attempt++) {
	reply = await sendAsk(ws, ask)
	const stuck = reply.control !== 'runner_ack' || reply.ok === false
	if (!stuck || attempt >= INSIST) break
	console.error(`… runner ${TARGET.slice(0, 8)} ${reply.ok === false ? `refused (${reply.result?.error ?? 'busy'})` : 'silent'} — insisting ${attempt}/${INSIST}`)
	await new Promise(r => setTimeout(r, Number(process.env.RUNNER_INSIST_MS || 3000)))
}
if (reply.control !== 'runner_ack') { console.error(`✗ ${op}: ${reply.error ?? 'no reply'}`); exitCode = 1 }
else if (op === 'snap' && reply.result?.got_snap) {
	console.error(`snap: Step ${reply.result.n} ok=${reply.result.ok} dige=${reply.result.dige}`)
	process.stdout.write(reply.result.got_snap.endsWith('\n') ? reply.result.got_snap : reply.result.got_snap + '\n')
} else if (op === 'assertions' && reply.result?.contract) {
	// the contract vs the evidence (never "roster" — that word is the Cluster runners'): each
	//  declared %Assertion against the Assertioning shelf, then the UNDECLARED sworn (not ok —
	//   every sworn wants declaring), then each sworn's microsnap — what it pointed at, at
	//    go-off time.
	const r = reply.result
	console.log(`assertions: ${r.book} — declared ${r.contract.length}, sworn ${r.sworn.length}, gaps ${r.gaps.length}`)
	for (const c of r.contract) {
		const hit = r.sworn.find(s => s.sentence === c.sentence)
		console.log(`  ${hit ? '✓' : '✗'} «${c.slug}» step ${c.n}${hit ? ` — sworn at step ${hit.n}` : ' — ABSENT'}: ${c.sentence}`)
	}
	for (const s of r.sworn.filter(s => !s.contracted)) console.log(`  ◇ undeclared (wants declaring) — sworn at step ${s.n}: ${s.sentence}`)
	for (const s of r.sworn.filter(s => s.microsnap)) {
		console.log(`  ⌖ «${s.sentence}» pointed at:`)
		for (const l of String(s.microsnap).split('\n')) console.log(`      ${l}`)
	}
	if (r.gaps.length) exitCode = 1
} else if (op === 'world' && reply.result && Array.isArray(reply.result.piers)) {
	// the live-resident diagnostic: the seal state (Piers + grant count) to stdout; the bulky
	//  depth-bounded world snap to a file so it greps without flooding the terminal.
	const r = reply.result
	console.log(`world: self ${r.self} — ${r.piers.length} pier${r.piers.length === 1 ? '' : 's'}, ${r.sealed_piers} mutually sealed`)
	for (const p of r.piers) console.log(`  ${p.mutual ? '⇄ MUTUAL' : '→ one-way (half-seal)'}  ${p.friendly ? p.friendly + ' ' : ''}${p.pub}  grants:[${p.grants.map(g => `${g.by}→${g.to}`).join(', ')}]`)
	if (!r.piers.length) console.log('  (no Piers — this tab knows no friends: nothing to play, shows "nobody online")')
	// the SUPPLY PIPELINE timeline (the human's "socklog for supply"): each stage mark with the
	//  delta from the previous mark, so a 20s gap between two marks names exactly what's slow.
	const tr = Array.isArray(r.supply_trace) ? r.supply_trace : []
	if (tr.length) {
		console.log(`\nsupply pipeline (last ${tr.length} marks; Δ = ms since previous mark):`)
		let prev = null
		for (const e of tr) {
			const d = prev == null ? 0 : e.t - prev
			prev = e.t
			const extra = Object.keys(e).filter(k => k !== 't' && k !== 'ev' && k !== 'id').map(k => `${k}=${e[k]}`).join(' ')
			const flag = d >= 2000 ? '  ⟵ SLOW' : (d >= 500 ? '  ⟵ slow' : '')
			console.log(`  +${String(d).padStart(6)}ms  ${e.ev.padEnd(18)} ${e.id ? '['+e.id+'] ' : ''}${extra}${flag}`)
		}
	} else console.log('\n(no supply-pipeline marks yet — hit play in the tab, then re-run `world`)')
	// the error-channel ring (Story_error's top-House capture) — the tab's throws over the CLI,
	//  so a boot/step wedge names its cause without VNC (the begun-wedge hunt, 2026-07-30).
	const er = Array.isArray(r.err_ring) ? r.err_ring : []
	if (er.length) {
		console.log(`\nerror-channel ring (last ${er.length}):`)
		for (const e of er) console.log(`  ${e.kind === 'warn' ? '⚠' : '✗'} ×${e.count}  [${e.where}] ${e.msg}`)
	}
	// Creduler diagnostic (the begun-wedge hunt, 2026-07-30) — Story() gates every run behind
	//  %Creduler_pending with no timeout; if it's stuck, this names which ghost(s) never went live.
	if (r.creduler) {
		const cd = r.creduler
		if (cd.pending) console.log(`\n⛔ Creduler_pending STUCK — ${cd.unmet.length}/${cd.total} ghost(s) never went live:\n${cd.unmet.map(u => `    ${u}`).join('\n')}`)
		else console.log(`\n✓ Creduler ready — all ${cd.total} ghosts live`)
	}
	// TEMPORARY checkpoint trace (H.diag) — the begun-wedge hunt, 2026-07-30.
	const dt = Array.isArray(r.diag_trace) ? r.diag_trace : []
	if (dt.length) { console.log(`\ndiag trace (last ${dt.length}):`); for (const d of dt) console.log(`  · ${d}`) }
	// the transfer HUD feed (top_House().c.xfer) — the same numbers TransferFace draws,
	//  readable here without a screenshot: rates, the active pull/serve, drops, recent frees.
	if (r.xfer) {
		const x = r.xfer
		const pulls = Object.values(x.pulls ?? {})
		const serves = Object.values(x.serves ?? {})
		console.log(`\nxfer: ${x.rx_kbps ?? 0}↓ / ${x.tx_kbps ?? 0}↑ KB/s${x.drops ? `, ${x.drops} dropped (last: ${x.last_drop})` : ``}${x.breaches ? `, ${x.breaches} breach${x.breaches === 1 ? `` : `es`} (last: ${x.last_breach})` : ``}${x.bulk_queued ? `, ${x.bulk_queued} page(s) queued behind the wire (§5.1 bulk lane — congested, not stalled)` : ``}`)
		for (const p of pulls) console.log(`  ⇊ ${p.title} ${p.held}/${p.total}${p.done ? ` ✓` : ``}${p.goodput_kbps != null ? `  goodput=${p.goodput_kbps}KB/s asked=${p.asked ?? 0} landed=${p.landed ?? 0}` : ``}`)
		for (const s of serves) console.log(`  ⇈ ${s.title} ${s.n}/${s.total} →${s.to}`)
		for (const f of (x.freed ?? []).slice(0, 3)) console.log(`  ↯ freed ${f.title}`)
	}
	// the CRATE CENSUS first — the shape of the mirror in a dozen numbers.  `homes > pubs` is a leak
	//  stated outright: duplicate %MusuThem homes for one pub all resolve to ONE shelf, so every reader
	//   that loops homes counts that crate once per duplicate.  `recs > distinct_ids` is the other leak
	//    (the same track standing twice in the tree) — they are different bugs and look identical in a total.
	if (r.crate_census) {
		const c = r.crate_census
		const dupHomes = c.them_homes > c.them_pubs
		console.log(`\ncrates: ${c.them_homes} %MusuThem home(s) over ${c.them_pubs} pub(s)${dupHomes ? `  ⟵ DUPLICATE HOMES — one crate counted ${c.them_homes}×` : ``}, ${c.self_homes} %MusuSelf`)
		for (const s of c.shelves) {
			const dup = s.recs - s.distinct_ids
			console.log(`  ⇄ ${s.pub}${s.dup_home > 1 ? ` #${s.dup_home}` : ``}  recs=${s.recs} distinct=${s.distinct_ids}${dup > 0 ? `  ⟵ ${dup} DUPLICATE record(s)` : ``}  flat=${s.flat} mags=${s.mags} clouds=${s.clouds}`)
		}
		for (const s of c.selfs) {
			const dup = s.recs - s.distinct_ids
			console.log(`  ⌂ ${s.pub}  recs=${s.recs} distinct=${s.distinct_ids}${dup > 0 ? `  ⟵ ${dup} DUPLICATE record(s)` : ``}`)
		}
	}
	if (r.world_snap) { writeFileSync('/tmp/runner_world.snap', r.world_snap); console.error(`  story world snap → /tmp/runner_world.snap  (${r.world_snap.length} bytes)`) }
	if (r.resident_snap) { writeFileSync('/tmp/runner_resident.snap', r.resident_snap); console.error(`  RESIDENT (radio) world snap → /tmp/runner_resident.snap  (${r.resident_snap.length} bytes) — grep it for Radio/MusuThem`) }
} else if (reply.ok === false) {
	// a refused/failed op — surface the runner's reason on stderr (busy lease, GC'd run, unknown Book…)
	console.error(`✗ ${op}: ${reply.result?.error ?? 'failed'}`)
	if (reply.result?.engagement) console.error(`  lease: ${JSON.stringify(reply.result.engagement)}`)
	exitCode = 1
} else {
	console.log(`${op}: ${JSON.stringify({ ok: reply.ok, ...reply.result })}`)
	// A needAC Book stalls PRE-run asking for a gesture (the run record only opens once AC lands).  Surface
	//  that — out of the blue if you never read Credence — so you know to go grant it in the runner tab.
	if (op === 'run' && reply.result?.needAC) console.error(`🎤 ${arg} needs AudioContext — grant it in the runner tab${watch ? ' (watching for the grant below; blocks in ~60s if not)' : '; add --watch to see the grant, or it blocks in ~60s'}`)
	// NO needsFSA NOTE (2026-08-06).  `needsFSA` in this reply is the BOOK's declaration echoed back
	//  (LiesFunk.svelte builds the run result from `ask.needsFSA`), NOT a refusal — it sits right beside
	//   `accepted:true`.  Printing a warning for it taught two readers in one day that the Book could not
	//    run, and a 69-Book sweep wrote off 16 Books on that basis; MusuHeist then ran 22/22 green on the
	//     same runner.  Runners essentially always have a share now, so the note was noise in the common
	//      case and a lie in the rest.  A REAL refusal now arrives as `state.refused` and is reported in
	//       the watch loop below, with the runner's own reason.
}

// --watch (run|state): poll state until the Storyrun phase settles done|failed, narrating each change.
if (watch && (op === 'run' || op === 'state') && reply.control === 'runner_ack') {
	const needAC = !!reply.result?.needAC
	const t0 = stamp
	let last = '', acWaited = false
	// the death-clock: `heard` = last time the tab answered a poll, `progress` = last time the run
	//  moved a step.  A single missed poll is NOT death — a sluggish (busy) tab can skip one 12s
	//   probe.  Only DEAD_MS (20s) of accumulated silence AND no forward progress is red, judged by
	//    the SHARED liveness() verdict.  Forward progress resets the clock (a run stepping IS life).
	let heard = Date.now(), progress = Date.now(), quietNoted = 0
	while (Date.now() - t0 < WATCH_MS) {
		await new Promise(r => setTimeout(r, 700))
		const s = await sendAsk(ws, { op: 'state' })
		if (s.control !== 'runner_ack') {
			const now = Date.now()
			if (liveness({ now, heard, progress }) === 'dead') {
				const quiet = Math.round((now - Math.max(heard, progress)) / 1000)
				console.error(`✗ runner DEAD — silent ${quiet}s (> ${DEAD_MS / 1000}s) with no progress — giving up`)
				exitCode = 1; break
			}
			if (now - quietNoted > 4000) {   // a busy tab within the DEAD budget: narrate, keep waiting
				quietNoted = now
				console.error(`… runner quiet ${Math.round((now - Math.max(heard, progress)) / 1000)}s/${DEAD_MS / 1000}s (busy?) — still waiting`)
			}
			continue
		}
		heard = Date.now()
		const run = s.result?.run, out = s.result?.outcome
		// A PRE-RUN GATE REFUSED (fsa | audio | collection): the runner declined before opening a run
		//  record, so there is no phase to watch and polling would just time out looking like a hang.
		//   Only ours — same Book, and stamped after we asked.  Name the reason and stop.
		const ref = s.result?.refused
		if (ref && ref.book === arg && ref.at >= t0) {
			console.error(`✗ ${arg} REFUSED by the runner — ${ref.why}`)
			console.error(`  nothing was tried; this is a capability block, not a test failure.`)
			exitCode = 1; break
		}
		// needAC: no run record yet ⇒ still stalling for the AC gesture (Lies_become_book_drive opens the
		//  record only AFTER AC is secured).  Keep the operator informed; cap the wait at ~65s (the runner's
		//   own 60s window) rather than the full WATCH_MS, and report BLOCKED/untried on lapse.
		if (needAC && !run) {
			if (!acWaited) { acWaited = true; console.error(`⏳ ${arg} is WAITING FOR AudioContext permission — grant it in the runner tab`) }
			if (Date.now() - t0 > 65000) { console.error(`⚠ AudioContext not granted within ~60s — run BLOCKED (untried, not a failure)`); exitCode = 1; break }
			continue
		}
		if (acWaited && run) { acWaited = false; console.error(`✓ AudioContext granted — running`) }
		const tag = run ? `${run.phase} ${run.n ?? '?'}/${run.total ?? '?'}` : 'no run'
		if (tag !== last) { console.log(`… ${JSON.stringify({ run, outcome: out })}`); last = tag; progress = Date.now() }   // a step advanced ⇒ reset the death-clock
		if (run && (run.phase === 'done' || run.phase === 'failed')) {
			// contract verdict (Seen_split rulings): a declared %Assertion whose %sworn never latched
			//  is a NAMED red, un-maskable by entropy — surface it distinctly from a step/dige failure.
			for (const g of (out?.gaps ?? [])) console.error(`  ✗ assertion «${g.slug}» expected by step ${g.n} — ABSENT: ${g.sentence}`)
			exitCode = out && out.ok ? 0 : 1; break
		}
	}
}

// A watched RUN settled — do NOT auto-release: `release` GCs the run, so it would throw away exactly what
//  you need to look at (a red run especially — the failing steps, the snap diffs).  Handing the runner
//   back must be a deliberate act AFTER inspecting.  So just REMIND, with the exact commands — inspect
//    first, release when genuinely done (which also frees it for the editor + other clients).
if (watch && op === 'run') {
	console.error('')
	console.error(exitCode !== 0
		? '  ⚠ run went RED — inspect BEFORE releasing (release throws the run away):'
		: '  run settled — inspect if you want, then hand the runner back:')
	console.error('      failing steps: node scripts/runner_ask.mjs steps')
	console.error('      one step snap: node scripts/runner_ask.mjs snap <n>')
	console.error('      release:       node scripts/runner_ask.mjs release   ← frees it for the editor')
}

try { ws.close() } catch {}
process.exit(exitCode)
