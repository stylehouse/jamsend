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
//    node scripts/runner_ask.mjs supervisor              # THE SUPERVISOR'S SCREEN, on a terminal: every
//                                                          #  registered watch with its mark, note, patience,
//                                                           #   advice and probe method, plus arrived: and the
//                                                            #    notice ring.  The roster stands on MUNDO, so
//                                                             #     no `snap` can reach it — this is the read.
//                                                              #      Works with --player= too: it is the only
//                                                               #       way to see what a listener's Butler says
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
//    node scripts/runner_ask.mjs console [--tail=N] [--grep=PAT] [--follow]  # pull a live tab's RAW console
//                                                          #  (log/warn/error) ring straight over the relay — no
//                                                           #   disk file, no reload, no DevTools copy-paste.  The
//                                                            #    tap installs UNCONDITIONALLY at boot; grep is a
//                                                             #     substring or /re/flags; --follow polls for new
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
//
//  A REMOTE NODE — another host's dev|prod server — needs `--live` beside RUNNER_URL:
//    RUNNER_URL=https://box.example:9999 node scripts/runner_ask.mjs runners --live
//    RUNNER_URL=https://box.example:9999 node scripts/runner_ask.mjs ping --player=96d0cf88 --live
//   The SOCKET could always point anywhere (an https origin becomes wss://…/relay), but DISCOVERY
//    could not: `runners` and --runner=/--player= all read the LOCAL wormhole/Cluster/toc.snap, which
//     is OUR relay's registry and names nobody on theirs.  `--live` learns the flock FROM THE RELAY
//      instead (see liveCensus below) and never opens the file.  It is also the honest way to ask
//       about our own relay — the registry is durable and remembers the long-dead; the wire cannot.
import { WebSocket } from 'ws'
import { readFileSync, writeFileSync } from 'node:fs'
// the SHARED liveness thresholds + verdict — the same numbers the ghost (LiesLies.svelte) reads,
//  so the CLI can no longer drift to a worse death criterion than the layer it's questioning.
import { DEAD_MS, SLUGGISH_MS, liveness } from '../src/lib/O/runner_liveness.mjs'

// `retain` was implemented runner-side (LiesFunk's op:'retain' → the Story world's keep_snaps) but
//  never listed here, so the CLI refused the one op that makes a MIDDLE step inspectable: without it
//   `snap 3` of a 9-step Book returns got_snap:null, trimmed 5 steps behind, and a flapping early step
//    cannot be diffed at all.  `retain on` sticks on w:Story.c across runs.
// --unknown-ok — permit a READ-ONLY ask against a live tab that will not classify.  See the resolver
//  below for why this is safe (the tab, not the CLI, is the authority on what it will do).
const UNKNOWN_OK = process.argv.includes('--unknown-ok')
let PLAYER_PUB = ''   // set by --player=: the one music page a slot-addressed ask is for (sendAsk stamps it into ask.pub)
const OPS = ['ping', 'probe', 'world', 'minisnap', 'pick', 'stemdex', 'supervisor', 'run', 'state', 'steps', 'snap', 'trace', 'assertions', 'declare', 'rungos', 'accept', 'release', 'runners', 'reload', 'socklog', 'dump', 'poke', 'retain', 'console', 'crew', 'tidy', 'ghost_load', 'atlas_callers', 'atlas_refresh', 'atlas_lint', 'electrode', 'lagoon']

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
		// `kind:hacker` marks a role:player row that is a CODE room (/BigWordland), not a music page:
		//  same door, same exclusion from dispatch, but it is the developer's OWN tab and saying
		//   "someone's music page" about it sent me looking for a channel that was already there.
		if (props.role === 'player') players.push({ pub, kind: props.kind })
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
	console.error('usage: node scripts/runner_ask.mjs <ping|probe|supervisor|run <Book>|state|steps|snap <n>|assertions|declare \'<sentence>\'|rungos|accept|release|runners|reload|socklog [on|off] [--reload]|dump|console [--tail=N] [--grep=PAT] [--follow]|pick <Ghost/X/Y.g> [<point>]|poke <verb>|crew|tidy <crew|rebuffs|forget:<pub>>|ghost_load <Ghost/X/Y.g> [--stand=Name] [--fresh] [--swap]|atlas_callers <name> [--stale]|atlas_refresh|atlas_lint [--sees] [--stale]|electrode [top|arm|disarm|reset|reduce|hangs|film|join] [--k=N] [--older=ms]|lagoon [seek|beads|defs|families|mentions|rot|rotwork|callers|lint|join|oaths|figurines|errands] [<name>] [--k=N]> [@uid] [--runner=<id>|--player=<id>] [--live] [--watch]')
	process.exit(2)
}

// ── the relay origin ────────────────────────────────────────────────────────────────────────
//  ONE derivation, read by the census, the resolvers and the main socket alike (it used to be
//   written out twice — the `runners` branch had its own copy, which is exactly how a remote
//    origin gets honoured by one path and not the other).
//  http→ws and https→wss both fall out of the same replace: `^http` → `ws` leaves the `s://`
//   in place, so `https://box:9999` becomes `wss://box:9999/relay`.  (Checked, not assumed.)
const HTTP       = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL     = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
// a single request waits just PAST sluggish before giving up — the old 8s was BELOW sluggish
//  (9s), so a busy-but-alive tab read as no-reply.  The `--watch` loop below then budgets a whole
//   DEAD_MS of accumulated silence (across polls) before it calls the runner dead.
const TIMEOUT_MS = Number(process.env.RUNNER_ASK_TIMEOUT_MS || (SLUGGISH_MS + 3000))
const WATCH_MS   = Number(process.env.RUNNER_WATCH_MS || 120000)
const stamp      = Date.now()
const cliAddr    = `runcli-${stamp}`   // ephemeral addr — relay LOGS the connect/disconnect; reply is corr-routed

// --live — discover from the RELAY, never from wormhole/Cluster/toc.snap.
//  A RUNNER_URL on ANOTHER HOST *implies* it, and must: the registry is a file on THIS box describing
//   the tabs on THIS box's relay.  A different PORT is still this disk (staging :9092 shares /app, so
//    the same registry describes it), but a different HOST is a different wormhole entirely — and
//     without this, `runners` against a remote node would confidently list OUR rows and mark every one
//      of them "✗ not answering", which is an instrument lying rather than declining.
const localHost = (() => { try { return /^(172\.17\.0\.1|localhost|127\.0\.0\.1|\[::1\]|::1)$/.test(new URL(HTTP).hostname) } catch { return true } })()
const live  = flags.has('--live') || !localHost

// READ-ONLY verbs — the only ones that may target a role:'player' tab (someone's actual music page).
//  Module-scope because it now gates TWO doors: explicit --player= targeting (below), and the
//   auto-court's humdinger veto (a player can answer a to:'runner' broadcast — see the veto).
const PLAYER_OPS = ['ping', 'probe', 'world', 'minisnap', 'supervisor', 'state', 'rungos', 'runners', 'socklog', 'dump', 'poke', 'reload', 'snap', 'steps', 'assertions', 'console', 'crew', 'tidy', 'atlas_callers', 'atlas_refresh', 'atlas_lint', 'lagoon']

// ── liveCensus — learn who is on THIS relay, FROM the relay ─────────────────────────────────
//  clusterRunners() above reads a LOCAL FILE.  Point RUNNER_URL at another host and that file is
//   still ours: it lists tabs on OUR relay and knows nothing about theirs, so --runner=/--player=/
//    `runners` were dead against a remote node even though the socket connected fine.  Here the
//     discovery comes off the wire instead: A TAB THAT ANSWERS IS THE DISCOVERY.
//
//  WHY A SWEEP AND NOT ONE BROADCAST.  The relay remembers an addr-less asker BY CORR (relay.ts
//   `ackBack`) and DELETES that mapping the instant the first runner_ack routes back — so a single
//    broadcast to:'runner' yields exactly ONE ack however many tabs answered; the rest are dropped
//     at the relay ("no asking socket (gone)").  Measured on two live tabs: one ack.  The relay has
//      no directory frame to ask instead — `who` is list-in only (and refuses a socket with no
//       verified hello), and enumerating `locals` is deliberately NOT built ("the roster stays
//        unlistable", relay.ts §4a).  BUT the winner ROTATES between rounds (the tab that just
//         answered is busy for a beat and loses the next race), so repeated broadcasts on FRESH
//          corrs enumerate the flock by attrition.  Measured over 20 rounds against four tabs:
//           f5da@0 a67a@1 96d0@3 58517@4 — all four inside five rounds, but arriving in a
//            stochastic order with idle rounds between them, which is why the stop condition is
//             `idle` CONSECUTIVE empty rounds and not "one quiet round".
//  ITS ONE HONEST LIMIT: a tab that is consistently slower than the flock may never win a round, so
//   a census can UNDER-report.  Measured over four sweeps of a four-tab relay: three listed all four,
//    and the one that listed three missed the tab that was mid-ghost_compile — i.e. the miss is a
//     genuinely wedged tab, which is also the tab an addressed ping still finds.  It can MISS a tab;
//      it never invents one.  Know the prepub already?  `--runner=<pub>` is addressed and never races.
//
//  ROLE, HONESTLY.  The ping ack's `role` is the tab's MACHINE role: Lies_runner_ask_recv answers
//   `Lies_is_runner(w) ? 'runner' : 'editor'`, and a Sounditron IS machine-role runner — both live
//    tabs here are `role:player` in the registry and both ack 'runner'.  Trusting that field would
//     put a Book on someone's music page, which is the one thing the --player split exists to
//      prevent.  So the census asks each discovered tab for `supervisor`, whose `humdinger` is the
//       "this is an end-user room" fact, and calls a humdinger a player.  `supervisor` is read-only
//        and already allowed on a player.  A tab that won't say (old code, no answer) is 'unknown'
//         and is refused for BOTH --runner= and --player= — fail closed, never guess.
//  The census carries no `client`, so Lies_engage_touch sees only an ephemeral addr: a listing
//   never touches anyone's engagement lease.
let censusSeq = 0
async function liveCensus({ classify = true,
	rounds = Number(process.env.RUNNER_CENSUS_ROUNDS || 24),      // hard cap on broadcast rounds
	min    = Number(process.env.RUNNER_CENSUS_MIN   || 8),        // …but never fewer than this many
	idle   = Number(process.env.RUNNER_CENSUS_IDLE   || 5),       // stop after this many rounds add nobody
	gapMs  = Number(process.env.RUNNER_CENSUS_GAP_MS || 300) } = {}) {
	const addr = `runcli-${Date.now()}-cs`
	const w2   = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(addr)}`)
	const up = await new Promise((res) => {
		const t = setTimeout(() => res(false), 5000)
		w2.on('open', () => { clearTimeout(t); res(true) })
		w2.on('error', () => { clearTimeout(t); res(false) })
	})
	if (!up) { try { w2.close() } catch {}; return null }   // relay unreachable — the caller words it
	const askOne = (to, theAsk, ms) => new Promise((res) => {
		const corr = `ra-cs-${Date.now()}-${censusSeq++}`
		const onMsg = (d) => {
			let m; try { m = JSON.parse(String(d)) } catch { return }
			if (m.corr !== corr) return
			w2.off('message', onMsg); clearTimeout(t); res(m)
		}
		const t = setTimeout(() => { w2.off('message', onMsg); res(null) }, ms)
		w2.on('message', onMsg)
		w2.send(JSON.stringify({ header: { type: 'runner_ask', from: addr, to, seq: Date.now(), corr }, ask: theAsk, corr }))
	})
	const found = new Map()
	let quiet = 0
	// `r < min` keeps the sweep going past its first quiet patch: the rotation is stochastic, so an
	//  early-stopping census under-reports (a 4-tab relay listed 3 twice out of three tries at idle-5
	//   alone).  A floor of `min` rounds costs ~2s and is the difference between a listing and a guess.
	for (let r = 0; r < rounds && (r < min || quiet < idle); r++) {
		// Sweep BOTH addr slots: runners bind ?addr=runner, but a diagnostic-armed music page binds
		//  ?addr=player (LiesLies Lies_channel_up, 2026-09-01) and a to:'runner' broadcast never reaches
		//   it — so without the to:'player' round an armed player is invisible here, findable only by an
		//    already-known --player=<pub>.  A slot with nobody bound just times out to null (harmless).
		let added = false
		for (const slot of ['runner', 'player']) {
			const a = await askOne(slot, { op: 'ping' }, 3500)
			const pub = a?.control === 'runner_ack' ? a.result?.self : null
			if (pub && !found.has(pub)) { found.set(pub, { pub, ack: a.result ?? {}, role: 'unknown', slot }); added = true }
		}
		if (added) quiet = 0; else quiet++
		if (!found.size && r >= 1) break        // two silent rounds ⇒ nobody home; don't burn the cap
		await new Promise(res => setTimeout(res, gapMs))
	}
	if (classify && found.size) {
		await Promise.all([...found.values()].map(async (f) => {
			// a tab found on the `player` slot is classified THROUGH that slot (see probeLive: the relay's
			//  own-door rule means an addressed ask never reaches a music page's role channel).
			const s = await askOne(f.slot === 'player' ? 'player' : f.pub, f.slot === 'player' ? { op: 'supervisor', pub: f.pub } : { op: 'supervisor' }, 8000)
			const h = s?.control === 'runner_ack' && s.ok !== false ? s.result?.humdinger : undefined
			f.role = h === true ? 'player'
				: h === false ? (f.ack.role === 'runner' ? 'runner' : String(f.ack.role ?? 'unknown'))
				: 'unknown'
		}))
	}
	try { w2.close() } catch {}
	return [...found.values()]
}
// The census, run at most once per invocation (the resolvers and `runners` may both want it).
//  Says so when --live was IMPLIED rather than asked for, so a remote reader knows which authority
//   answered them — the wire, not the file they might otherwise assume.
let censusOnce
const census = async (opts) => (censusOnce ??= (() => {
	if (!localHost && !flags.has('--live')) console.error(`⇢ ${HTTP} is another host — discovering off ITS relay (our wormhole/Cluster registry describes this box only)`)
	return liveCensus(opts)
})())
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
//  `--live` (and a registry that can say nothing — no file, no rows, e.g. a REMOTE relay) skips the
//   file entirely and lists what the wire says instead; see liveCensus.
if (op === 'runners') {
	const rs = live ? [] : clusterRunners()
	if (live || !rs.length) {
		const found = await census({})
		if (found == null) { console.error(`✗ relay ${WS_URL}: unreachable — no registry read (--live), so there is nothing to fall back on`); process.exit(1) }
		if (!found.length) {
			console.error(`no tab answered a to:'runner' broadcast on ${WS_URL} — nothing is booted there (a runner is ?B=<Book>; a player must be diagnostic-armed to be addressable at all)`)
			if (!live) console.error('  (and wormhole/Cluster/toc.snap named no runner either)')
			process.exit(1)
		}
		console.error(`⇢ LIVE census off ${WS_URL} — ${found.length} tab(s) answered; wormhole/Cluster/toc.snap was NOT read`)
		for (const f of found) {
			const tag = f.role === 'player' ? (f.kind === 'hacker'
					? `  ⌨ hacker (a code room — --player= to address)`
					: `  ♪player (someone's music page — --player= to address)`)
				: f.role === 'runner' ? '' : `  ⚠ role UNKNOWN (this tab won't say — refused for --runner=/--player=)`
			const busy = f.ack?.running?.book ? `  running:${f.ack.running.book}/${f.ack.running.phase}` : ''
			const lease = f.ack?.engagement?.status === 'active' ? `  lease:${String(f.ack.engagement.client).slice(0, 8)}` : ''
			console.log(`${f.pub}${f.ack?.favourite_client ? `  ★${String(f.ack.favourite_client).slice(0, 8)}` : ''}${tag}${busy}${lease}  ✓ live`)
		}
		process.exit(0)
	}
	let alive = null   // null ⇒ relay unreachable (liveness unknown); else the Set of prepubs that acked
	try {
		const addr = `runcli-${Date.now()}-ls`
		const w2   = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(addr)}`)
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
	for (const p of players) console.log(`${p.pub}  ${p.kind === 'hacker' ? `⌨ hacker (a code room — --player= to address)` : `♪player (someone's music page — --player= to address)`}${alive != null && alive.has(p.pub) ? '  ✓ live' : ''}`)
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
// ── probeLive — ADDRESSED live resolution (2026-08-13) ──────────────────────────────────────
//  The census is a BROADCAST rotation and the relay spends each round's corr on the FIRST
//   runner_ack (relay.ts `ackBack`, deleted on receipt) — so a NAMED tab that keeps losing that
//    race is never enumerated, and an explicit --player=<addr> exits 2 while the tab's own console
//     shows it answering every ping (measured 2026-08-13: f469a1ec50f5a878 answered every census
//      broadcast, lost every round to three faster tabs, and the relay dropped each ack with
//       "no asking socket (gone)").  An ADDRESSED frame never races: to:<addr> routes point-to-
//        point and the single ack is corr-routed home.  So when the caller NAMES a tab, ask it BY
//         NAME; the census stays as the no-id discovery path and the last-resort fallback.
//  Classification is the census's own law, unchanged: the ping ack's role is the MACHINE role (a
//   Sounditron acks 'runner'), so `supervisor`'s humdinger decides player-vs-runner, and a tab
//    that won't say is 'unknown' and matches neither — fail closed, never guess.
//  Returns: a pub string (verified match) · {wrong,role} (answered by address but is the other
//   kind — a precise refusal beats a census that would mis-file it) · null (no addressed ack).
async function probeLive(id, want) {
	// candidate FULL addrs — an addressed frame needs the whole prepub: the literal id when it is
	//  one, plus (LOCAL relay only) registry prefix expansions.  A remote host's tabs are not in
	//   OUR registry (the whole point of --live), so a remote prefix can only go to the census.
	const cands = []
	if (/^[0-9a-fA-F]{16}$/.test(id)) cands.push(id)
	if (localHost) {
		const rs = clusterRunners()   // (re)parses the registry; also (re)fills `players`
		for (const row of [...players, ...rs]) if (row.pub.startsWith(id) && !cands.includes(row.pub)) cands.push(row.pub)
	}
	if (!cands.length) return null
	const addr = `runcli-${Date.now()}-pb`
	const w2   = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(addr)}`)
	const up = await new Promise((res) => {
		const t = setTimeout(() => res(false), 5000)
		w2.on('open', () => { clearTimeout(t); res(true) })
		w2.on('error', () => { clearTimeout(t); res(false) })
	})
	if (!up) { try { w2.close() } catch {}; return null }   // relay unreachable — the census path words it
	const askOne = (to, theAsk, ms) => new Promise((res) => {
		const corr = `ra-pb-${Date.now()}-${censusSeq++}`
		const onMsg = (d) => {
			let m; try { m = JSON.parse(String(d)) } catch { return }
			if (m.corr !== corr) return
			w2.off('message', onMsg); clearTimeout(t); res(m)
		}
		const t = setTimeout(() => { w2.off('message', onMsg); res(null) }, ms)
		w2.on('message', onMsg)
		w2.send(JSON.stringify({ header: { type: 'runner_ask', from: addr, to, seq: Date.now(), corr }, ask: theAsk, corr }))
	})
	let wrong = null
	try {
		for (const pub of cands) {
			// 3 addressed tries: a busy tab can miss one 4s window; an unbound addr answers fast
			//  (the relay's own `undeliverable`), so a dead candidate costs one round, not three.
			let a = null
			for (let t = 0; t < 3 && a?.control !== 'runner_ack'; t++) {
				// A MUSIC PAGE IS ASKED THROUGH ITS SLOT, NOT ITS PUB (2026-09-06).  The relay's own-door rule
				//  (relay.ts deliverLocal) hands every to:<prepub> frame to the tab's STATION socket alone, and a
				//   music page has one — so its Lies channel (?addr=player, the only socket that answers
				//    runner_ask) never sees an addressed ask, and every --player= probe timed out for a day
				//     while the tab was alive.  The `player` slot fan-out does reach it; `ask.pub` names the one
				//      tab meant and every other player stays silent (Lies_runner_ask_recv).
				a = await askOne(want === 'player' ? 'player' : pub, want === 'player' ? { op: 'ping', pub } : { op: 'ping' }, 4000)
				if (a?.control === 'undeliverable') break
			}
			if (a?.control !== 'runner_ack') continue
			const s = await askOne(want === 'player' ? 'player' : pub, want === 'player' ? { op: 'supervisor', pub } : { op: 'supervisor' }, 8000)
			const h = s?.control === 'runner_ack' && s.ok !== false ? s.result?.humdinger : undefined
			const role = h === true ? 'player'
				: h === false ? (a.result?.role === 'runner' ? 'runner' : String(a.result?.role ?? 'unknown'))
				: 'unknown'
			if (role === want) return pub
			// AN ADDRESSED ACK PROVES THE TAB IS THERE; only its self-description is missing (2026-09-06,
			//  the owner's eed).  The census tells a music page from a test runner by asking `supervisor`
			//   and reading `humdinger`; a tab that misses that 8s window classifies 'unknown' and is
			//    refused for BOTH roles.  Right for a mutating op — but it also locked read-only
			//     introspection out of the one tab where the bugs actually live, since a busy music page
			//      (heavy Repli, a laggy panel) can be perfectly alive and still miss the window.
			//  Safe because this gate was never the authority.  LiesFunk says so itself: "The CLI's
			//   PLAYER_OPS gate is advisory; THIS is the authority — a music tab can be introspected but
			//    never made to run a Book or reload."  The tab refuses run|release|retain|accept|declare|
			//     reload|ghost_load on its own, so --unknown-ok can only widen READ-ONLY asks.
			if (role === 'unknown' && UNKNOWN_OK && want === 'player' && PLAYER_OPS.includes(op)) {
				console.error(`… ${pub.slice(0, 8)} answered but would not classify — proceeding read-only (--unknown-ok)`)
				return pub
			}
			wrong = { wrong: pub, role }
		}
	} finally { try { w2.close() } catch {} }
	return wrong
}
// LIVE resolution — the same selector, answered by the RELAY instead of the local file.  Used when
//  --live is given, and as an automatic fallback when the registry can say nothing (a remote node's
//   registry is on ITS disk, not ours).  `want` is the role the census must agree on: a tab that will
//    not say what it is ('unknown') matches neither, so a silent/old tab is never mistaken for the
//     other kind.  No id ⇒ the last one found, mirroring the file resolver's "latest".
//  A GIVEN id goes ADDRESSED first (probeLive above) — the census cannot be trusted to reach a
//   specific tab (its broadcast corr is spent on the first ack), only to discover *some* tabs.
async function resolveLive(id, want) {
	if (id) {
		const hit = await probeLive(id, want)
		if (typeof hit === 'string') return hit
		if (hit?.wrong) {
			console.error(`✗ --${want}=${id}: ${hit.wrong.slice(0, 8)} answered its addressed ping but is role:'${hit.role}', not '${want}'${
				hit.role === 'player' ? ' — a Sounditron; address it with --player=' : hit.role === 'runner' ? ' — a test runner; address it with --runner=' : " (it won't say what it is — old code? reload it)"}`)
			process.exit(2)
		}
		console.error(`⇢ --${want}=${id}: no addressed ack — sweeping ${WS_URL} instead (census; slower and can under-report)`)
	}
	const found = await census({})
	if (found == null) { console.error(`✗ relay ${WS_URL}: unreachable — cannot resolve --${want}=${id || ''} live`); process.exit(2) }
	const rs = found.filter(f => f.role === want)
	const hit = id ? (rs.find(f => f.pub === id) ?? rs.find(f => f.pub.startsWith(id))) : rs[rs.length - 1]
	if (!hit) {
		const shy = found.filter(f => f.role === 'unknown').length
		console.error(`✗ --${want}=${id || '(latest)'}: no live role:'${want}' tab on ${WS_URL} answered${found.length ? ` (${found.length} tab(s) did: ${found.map(f => `${f.pub.slice(0, 8)}=${f.role}`).join(' ')})` : ''}${shy ? ` — ${shy} would not say what they are (old code? ask \`runners --live\`)` : ''}`)
		process.exit(2)
	}
	return hit.pub
}
if (runnerSel !== undefined) {
	const pub = live ? await resolveLive(runnerSel, 'runner') : (resolveRunner(runnerSel) ?? await (async () => {
		console.error(`⇢ --runner=${runnerSel || '(latest)'} not in wormhole/Cluster/toc.snap — asking the relay instead (--live)`)
		return resolveLive(runnerSel, 'runner')
	})())
	TARGET = pub
}
// --player=<id> — address a Sounditron (role:'player').  READ-ONLY VERBS ONLY, refused loudly otherwise:
//  a player is someone's actual music page, and `run` would put a Book on it (the whole thing the role
//   split exists to prevent) while accept/release/declare are run-lifecycle verbs that presuppose one.
//    `reload` IS allowed — it is the one mutating verb with a real diagnostic purpose (reproduce a
//     one-sided reload) and it costs the human a moment of music, not a hijacked tab.
if (playerSel !== undefined) {
	if (runnerSel !== undefined) { console.error('✗ pass --runner= or --player=, not both'); process.exit(2) }
	if (!PLAYER_OPS.includes(op)) { console.error(`✗ '${op}' is not allowed on a --player (someone's music page). Allowed: ${PLAYER_OPS.join(' ')}`); process.exit(2) }
	// EXPLICIT ONLY stays explicit live too: resolveLive(want:'player') matches a tab only when its own
	//  `supervisor` says humdinger — never on the ping ack's role, which reads 'runner' for a Sounditron.
	if (!playerSel) { console.error('✗ --player needs an id (no bare form, no "latest player" — picking someone\'s music tab by accident is what this shape prevents)'); process.exit(2) }
	const pub = live ? await resolveLive(playerSel, 'player') : (resolvePlayer(playerSel) ?? await (async () => {
		console.error(`⇢ --player=${playerSel} not in wormhole/Cluster/toc.snap — asking the relay instead (--live)`)
		return resolveLive(playerSel, 'player')
	})())
	// the main ask goes to the `player` SLOT with the pub in the ask (own-door rule — see probeLive)
	PLAYER_PUB = pub
	TARGET = 'player'
}
if (op === 'run' && !arg)  { console.error('run needs a Book: node scripts/runner_ask.mjs run <Book>'); process.exit(2) }
if (op === 'tidy' && !arg) { console.error('tidy needs a target: node scripts/runner_ask.mjs tidy <crew|rebuffs|forget:<pub prefix>> --player=<id>   (the tab must be armed: socklog on --reload)'); process.exit(2) }
if (op === 'poke' && !arg) { console.error('poke needs a verb: node scripts/runner_ask.mjs poke <Radio_toggle|Radio_skip|Radio_source_toggle|Sounditron_diag_toggle> [--runner=<id>]'); process.exit(2) }
if (op === 'socklog' && arg && arg !== 'on' && arg !== 'off') { console.error('socklog takes on|off (default on): node scripts/runner_ask.mjs socklog [on|off] [--reload] [--runner=<id>]'); process.exit(2) }
if (op === 'declare' && !arg) { console.error('declare needs the sworn sentence (quote it — byte-identical to `assertions` output): node scripts/runner_ask.mjs declare \'<sentence>\''); process.exit(2) }
if (op === 'snap' && !arg) { console.error('snap needs a step number: node scripts/runner_ask.mjs snap <n>'); process.exit(2) }
if (op === 'trace' && !arg) { console.error('trace needs a step number: node scripts/runner_ask.mjs trace <n>  (the step\'s beliefs-cycle trace + causal|timeout quiescent label)'); process.exit(2) }
if (op === 'minisnap' && !arg) { console.error('minisnap needs a pointer path: node scripts/runner_ask.mjs minisnap \'radio>Radio\' [--depth=4] [--nodes=400] [--diff]\n  pointers: root>step>step  (root ∈ mundo|radio|story|self; step = a mainkey, e.g. `Body` or `Body,role:Cave`; `;` joins several paths)\n  --diff shows the change vs your PREVIOUS read of the same pointer (the ring persists on the tab — call again to watch it evolve)'); process.exit(2) }

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
if (op === 'tidy') ask.what = arg          // crew | rebuffs | forget:<pub prefix> — refused tab-side unless socklog is armed
if (op === 'ghost_load') {
	// bring a compiled Ghost/**.g up on the live runner and (--stand=Name) mint A:Name/w:Name so its
	//  worker ticks — the manifest-free door for a new ghost (Ghost/L/).  Runner-only tab-side.
	//  --fresh: drop any ALREADY-standing A:Name first — plain --stand is find-or-create, so a ghost
	//   whose own do_fn only rosters once (Atlas: `if (!w.c.rostered)`) silently keeps a stale roster
	//    across a re-stand otherwise (confirmed live 2026-09-06: widening Atlas's own corpus and
	//     re-standing without --fresh kept the old, narrower doc count).
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	ask.path = arg
	const s = flagVal('--stand'); if (s !== undefined) ask.stand = s
	if (flags.has('--fresh')) ask.fresh = 1
	// --swap: the gen is ALREADY imported on this tab (an L ghost you just recompiled) — re-import it
	//  with a cache-busting query and re-enrol, the Creduler_reswap dance for one non-spine ghost, so a
	//   recompiled L ghost takes without a tab reload.  Give it ~3s before you use the new methods.
	if (flags.has('--swap'))  ask.swap = 1
	// --nocache: stand it COLD — no Dexie adopt, every doc really parsed.  The expensive case, and the
	//  one every measurement had been silently skipping (see the note in LiesFunk's ghost_load).
	if (flags.has('--nocache')) ask.nocache = 1
}
if (op === 'atlas_callers') ask.name = arg   // "who calls X" — {doc, line, via, kind} per site; needs A:Atlas standing first
if (op === 'atlas_callers' || op === 'atlas_refresh' || op === 'atlas_lint') {
	// every atlas_* query REFRESHES first (re-list roots, map the movers inline) so the answer is as
	//  fresh as the disk — use nudges a pass, no timer.  --stale skips that for a cheap re-ask.
	//  atlas_lint: missing/beyond_eof file:line links + orphan defs; --sees adds the %see sentences no
	//   Book fixture has recorded (one read per Book, so opt-in).
	if (flags.has('--stale')) ask.stale = 1
	if (flags.has('--sees'))  ask.sees  = 1
}
if (op === 'pick') {
	// fire the Doc change a search hit fires, so it can be MEASURED (Clerkdesk_todo leg 1):
	//   electrode arm → electrode reset → pick <path> [<point>] → electrode top
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	ask.path = arg
	const pt = argv[argv.indexOf(arg) + 1]
	if (pt && !pt.startsWith('-')) ask.point = pt
	const p = flagVal('--point'); if (p !== undefined) ask.point = p
}
if (op === 'lagoon') {
	// the reader layer over the censuses — see Ghost/L/Lagoon.g.  `lagoon <verb> [name]`.
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	ask.verb = arg || 'families'
	const nm = argv[argv.indexOf(arg) + 1]
	if (nm && !nm.startsWith('-')) ask.name = nm
	const k = flagVal('--k'); if (k !== undefined) ask.k = Number(k)
}
if (op === 'electrode') {
	// Electrode (Ghost/L/Electrode.g) — both ends of every ghost call.  Needs A:Electrode standing
	//  (ghost_load Ghost/L/Electrode.g --stand=Electrode).  top (default) prints the hottest flows by count
	//   and by time; arm/disarm put the coats on/off every ghost method on the tab; reduce folds the
	//    lossless tally into w:Electrode/%Graph (read it with minisnap 'mundo>A:Electrode>w:Electrode>Graph');
	//     hangs lists frames entered and not exited, oldest first; film is the raw last-k marks with deltas.
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	ask.verb = arg || 'top'
	const k = flagVal('--k'); if (k !== undefined) ask.k = Number(k)
	const o = flagVal('--older'); if (o !== undefined) ask.older = Number(o)
}
if (op === 'console') {
	// pull the live tab's console ring; tail/grep applied RING-SIDE so the reply carries only the
	//  wanted lines.  --follow polls below, streaming only lines newer than the last read.
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	const t = flagVal('--tail'); if (t !== undefined) ask.tail = Number(t)
	const g = flagVal('--grep'); if (g !== undefined) ask.grep = g
}
if (op === 'retain') ask.on = arg === 'off' ? false : true   // keep every step's got_snap, not just the last 5
if (op === 'minisnap') {
	// targeted, bounded C-tree read; --diff shows the change vs the previous read of the SAME pointer.
	const flagVal = (name) => { const f = argv.find(a => a.startsWith(name + '=')); return f ? f.split('=').slice(1).join('=') : undefined }
	ask.pointers = arg
	const d = flagVal('--depth'); if (d !== undefined) ask.depth = Number(d)
	const n = flagVal('--nodes'); if (n !== undefined) ask.nodes = Number(n)
	if (flags.has('--diff')) ask.diff = 1
}
if (uid) ask.uid = uid

// (HTTP / WS_URL / TIMEOUT_MS / WATCH_MS / stamp / cliAddr are declared with the origin block near
//  the top — the census and the resolvers run BEFORE this point and need them.)

// fmtConLine — one console-ring entry as `HH:MM:SS.mmm LV │ line`, level upper-cased and padded so a
//  scan down the column reads.  A tab in another TZ still lines up (times are ITS wall clock, which is
//   what you want when correlating with its DevTools).
const conSeen = new Set()   // t|line keys already printed, so --follow never repeats a line
function fmtConLine(c) {
	const d = new Date(c.t)
	const hh = String(d.getHours()).padStart(2, '0'), mm = String(d.getMinutes()).padStart(2, '0')
	const ss = String(d.getSeconds()).padStart(2, '0'), ms = String(d.getMilliseconds()).padStart(3, '0')
	const lv = String(c.lv ?? 'log').toUpperCase().padEnd(5)
	return `${hh}:${mm}:${ss}.${ms} ${lv} │ ${c.line}`
}

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
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: to ?? TARGET, seq: Date.now(), corr }, ask: PLAYER_PUB ? { ...theAsk, pub: PLAYER_PUB } : theAsk, corr }))
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

// relayCensus — ASK THE RELAY WHO IS BOUND, instead of asking the flock to raise its hand.
//  Every discovery path below this line was built on a role BROADCAST, and a broadcast cannot
//   enumerate: the relay spends the asker's `corr` on the FIRST ack, so one round finds exactly one
//    tab however many answered — which is why `census()` above has to sweep in stochastic rounds with a
//     minimum floor "because an early-stopping census under-reports".  The relay never needed asking
//      that way; it holds `locals` (addr → sockets) and knows the answer outright.
//  ITS `roles` ARE BETTER EVIDENCE THAN AN ACK.  A row's role is what the socket DECLARED at `become`
//   (the relay stamps `declaredRole`), not what the tab says about itself when asked — and the ack's
//    self-report is exactly the fact the comment at `isRunner` calls useless ("both live tabs ack
//     role:'runner'" because a Sounditron is machine-role runner).
//  ⚠ It USED to read the `?addr=` the socket dialled with, and that is why the census row survived the
//   2026-09-10 "a role is not an address" change: role channels now dial ADDR-LESS (Tribunal.g
//    `Socket_real`), so `qaddr` is empty for them and `declaredRole` is the whole answer.  The relay
//     still falls back to `qaddr` for anything that dialled the old way.
//  Returns null when the relay does not answer (an older relay, or a foreign node) so every caller
//   falls through to the broadcast road unchanged — this is additive, and removes nothing yet.
function relayCensus(ws, ms = 3000) {
	const corr = `rc-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		const t = setTimeout(() => { ws.off('message', onMsg); resolve(null) }, ms)
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			// `census_error` is the relay REFUSING us: the bound list is presence, and presence answers
			//  only to a hello-verified socket (relay.ts, gated as `who` is).  This CLI signs no hello,
			//   so on a gated relay it lands here every time and falls through to the broadcast court
			//    below — vaguer, but exactly what it did before the census existed.  Signing the ask
			//     (§3.4.3) is what earns the deterministic road back.
			if (m.control === 'census_error') { clearTimeout(t); ws.off('message', onMsg); return resolve(null) }
			if (m.control !== 'census') return
			if (m.corr && m.corr !== corr) return
			clearTimeout(t); ws.off('message', onMsg); resolve(Array.isArray(m.rows) ? m.rows : [])
		}
		ws.on('message', onMsg)
		try { ws.send(JSON.stringify({ control: 'census', corr })) } catch { clearTimeout(t); ws.off('message', onMsg); resolve(null) }
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
//  PER ORIGIN, since RUNNER_URL can now point at another node: a prepub courted on OUR relay means
//   nothing on theirs, and a cross-node sticky just costs a wasted addressed ping before the court
//    falls through.  The default origin keeps the historic path, so an existing stash still counts.
const STICKY_PATH = `/tmp/runner_ask.target${HTTP === 'http://172.17.0.1:9091' ? '' : '.' + HTTP.replace(/[^A-Za-z0-9]+/g, '_')}`
// the census's candidate list, kept for the re-court below: courting is DETERMINISTIC now, which is the
//  whole point and also means a sick first candidate is chosen every single time.  The broadcast was
//   accidentally better here — whichever tab answered first was at least answering.
let courtCands = []
let censusRefused = 0
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
//  …AND THE ACK'S `role` IS NOT ENOUGH (2026-08-12).  Lies_runner_ask_recv answers `role` from
//   `Lies_is_runner(w)`, which is the tab's MACHINE role — and a Sounditron IS machine-role runner
//    (Auto boots a Big*land room with boot_role 'runner' + humdinger).  Measured: both live tabs on
//     :9091 are `role:player` in the registry and BOTH ack `role:'runner'`, so this filter shoos
//      away nobody and the door the comment above declares shut is still open.  The registry knew
//       the difference and the wire did not — which is precisely the gap a remote node lives in.
//        The veto below closes it with the one live fact that CAN tell them apart.
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
	// 2. THE RELAY'S OWN ANSWER, before any broadcast.  Ask which addresses are bound and which came
	//     through the `runner` door, then ping each candidate DIRECTLY — deterministic, one round, and
	//      it sees the whole flock rather than whichever tab the relay favoured with the corr.
	//     Every runner is addressed by prepub from here on, which is the shape that survives deleting
	//      the `?addr=runner` seat entirely (Social_demarcation_todo §0, step 2 of 4).
	//     Silent fallthrough by design: no census (older relay, foreign node) ⇒ the broadcast below runs
	//      exactly as before.  Nothing is removed until this road is proven.
	if (TARGET === 'runner') {
		const rows = await relayCensus(ws)
		if (rows === null) censusRefused = 1
		// A TAB THAT ALSO DECLARED `player` IS A MUSIC PAGE, whatever else it declared (measured live
		//  2026-09-09, the first thing role-keeping showed: eed had THREE sockets and one of them had
		//   declared `runner`, so it was sitting in the shared runner seat — the exact thing Auto.svelte's
		//    humdinger exclusion exists to prevent).  `includes('runner')` alone would court it, and the
		//     downstream veto would then have to shoo it away on every single invocation.
		//  Refuse it HERE, where the evidence is: `player` is a claim only an end-user room makes, and no
		//   real runner makes it.  The veto stays as the deeper gate — this just stops us walking into it.
		const cands = (rows ?? [])
			.filter(r => r.identity && (r.roles ?? []).includes('runner') && !(r.roles ?? []).includes('player'))
			.map(r => r.addr)
		courtCands = cands
		if (cands.length) {
			const acks = (await Promise.all(cands.map(p => sendAsk(ws, { op: 'ping', client: CLIENT }, p, 4000))))
				.filter(a => a.control === 'runner_ack' && isRunner(a))
			const pick = acks.find(isMine) ?? (op === 'run' ? (acks.find(isFree) ?? acks[0]) : acks[0])
			if (pick?.result?.self) {
				TARGET = pick.result.self
				if (cands.length > 1) console.error(`⇢ relay census: ${cands.length} runner-door tabs — courting ${TARGET.slice(0, 8)}${isMine(pick) ? ' (holds our lease)' : ''}; the rest stay untouched`)
			}
		}
	}
	// 3. no (usable) sticky and no census — broadcast-court: one role ping, gather the acks, pick
	//     our-lease ▸ (run) free ▸ first.
	if (TARGET === 'runner') {
		const allAcks = await collectAcks(ws, { op: 'ping', client: CLIENT })
		const acks = allAcks.filter(isRunner)
		const shooed = allAcks.length - acks.length
		if (shooed > 0) console.error(`⇢ ignoring ${shooed} non-runner tab${shooed === 1 ? '' : 's'} that answered the runner broadcast (role≠runner — someone's music page)`)
		// SAY WHY THE VAGUE ROAD IS THE ONE WE ARE ON (2026-09-09).  A broadcast court that comes home
		//  empty is reported downstream as "no reply in 12s (runner not connected?)", which is a LIE when
		//   two healthy runners are sitting right there — measured tonight, minutes after the census was
		//    gated.  The mechanism is the seat itself: several sockets bind `runner` (one of them, live,
		//     an end-user music page that had declared it), a broadcast fans to all of them, and the relay
		//      spends our corr on whichever answers FIRST.  When that is the humdinger, the court comes
		//       home with nothing and the flock is invisible to us.
		//  The census could see straight through that and cannot be used here, because this CLI signs no
		//   hello and the relay rightly refuses presence to unverified askers.  So name the real cause
		//    rather than let a human read "no runner" and go looking for a dead tab.
		if (!allAcks.length && censusRefused) {
			console.error(`⇢ the relay refused a census (this CLI signs no hello) and the '${'runner'}' broadcast came home empty.`)
			console.error(`   That is NOT proof no runner is up: several sockets share that seat and the relay spends our corr on the first answer.`)
			console.error(`   Address one directly if you know it:  --runner=<prepub>   ·  list them:  node scripts/runner_ask.mjs runners`)
		}
		if (!acks.length && allAcks.length) {
			console.error(`✗ no role:'runner' tab answered — only ${allAcks.length} player/other tab${allAcks.length === 1 ? '' : 's'} did.  Boot a runner (?B=<Book>); refusing to put a Book on a listener's page.`)
			process.exit(3)
		}
		// keep every tab that answered, so a bad first pick is recoverable (see the re-court below).
		courtCands = acks.map(a => a?.result?.self).filter(Boolean)
		const pick = acks.find(isMine) ?? (op === 'run' ? (acks.find(isFree) ?? acks[0]) : acks[0])
		if (pick?.result?.self) {
			TARGET = pick.result.self
			if (acks.length > 1) console.error(`⇢ ${acks.length} runners acked — courting ${TARGET.slice(0, 8)}${isMine(pick) ? ' (holds our lease)' : ''}; the rest stay untouched`)
		}
	}
	// still 'runner' ⇒ zero acks — let the real ask surface the usual no-reply/undeliverable error
	// THE HUMDINGER VETO — the last gate before a non-read op lands on a tab nobody named.  A courted
	//  tab arrived by ANSWERING a broadcast, and its ack cannot say whether it is a test runner or
	//   somebody's music page (see isRunner above), so ask the tab itself: `supervisor` carries
	//    `humdinger`, "this is an end-user room".  Gated by the SAME list that gates explicit --player=
	//     targeting, so the accidental door and the deliberate one now agree on what a player may take.
	//  Only a POSITIVE humdinger refuses: a tab that doesn't answer (older code, busy) is left exactly
	//   as permitted as it is today — this can only ever refuse more than before, never less.
	//  And a refusal RE-COURTS rather than dead-ending: the broadcast hands back ONE tab (the relay
	//   spends the corr on the first ack), so "the tab that answered is a music page" says nothing
	//    about the flock — a real runner may be sitting right beside it, and a stale player sticky
	//     would otherwise refuse every run forever.  So sweep properly (liveCensus, which classifies)
	//      and pick a role:'runner' tab; only an all-player relay is a refusal.
	if (TARGET !== 'runner' && !PLAYER_OPS.includes(op)) {
		const s = await sendAsk(ws, { op: 'supervisor' }, TARGET, 8000)
		if (s.control === 'runner_ack' && s.result?.humdinger === true) {
			console.error(`⇢ courted ${TARGET.slice(0, 8)} is a HUMDINGER (an end-user music room) — not putting '${op}' on it; sweeping ${WS_URL} for a real runner`)
			const rs = ((await census({})) ?? []).filter(f => f.role === 'runner')
			const engOf = (f) => f.ack?.engagement
			const pick = rs.find(f => engOf(f)?.client === CLIENT && engOf(f)?.status === 'active' && !engOf(f)?.stale)
				?? (op === 'run' ? (rs.find(f => { const e = engOf(f); return !e || e.status !== 'active' || e.stale || e.client === CLIENT }) ?? rs[0]) : rs[0])
			if (!pick) {
				console.error(`✗ no role:'runner' tab on ${WS_URL} — every tab that answered is someone's music page.  Boot a runner (?B=<Book>); refusing to put '${op}' on a listener's page.  Read-only on that tab: --player=${TARGET}`)
				process.exit(3)
			}
			TARGET = pick.pub
			console.error(`⇢ courting ${TARGET.slice(0, 8)} instead — a real runner (the music tab stays untouched)`)
		}
	}
}
if (TARGET !== 'runner') { try { writeFileSync(STICKY_PATH, TARGET + '\n') } catch { /* stash is best-effort */ } }

let exitCode = 0
// INSIST: when courting a NAMED tab (--runner= or --player=), DON'T failover — retry the SAME target on a
//  busy refusal or silence (an occupied or half-open tab), up to RUNNER_INSIST_TRIES.  The role broadcast
//   stays single-shot.  --player joined 2026-08-13: its verbs are read-only by construction (PLAYER_OPS),
//    so insisting is harmless, and a listening tab mid-decode legitimately misses a single 12s window.
const INSIST = (runnerSel !== undefined || playerSel !== undefined) ? Number(process.env.RUNNER_INSIST_TRIES || 5) : 1
// AUTO-STAND THE LAND, because a tab reload silently un-stands it and every L verb then refuses.
//  `Ghost/L/*` are outside the spine manifest by design, so `A:Atlas`/`A:Lagoon`/`A:Electrode` exist
//   only because someone stood them — and ANY edit to app source hot-reloads the tab and drops all
//    three.  During a working session that happens constantly, and the refusal is always the same
//     sentence naming the exact command that fixes it.  A CLI that can read that sentence and will not
//      act on it is making a human retype what it already knows.
//   ONE attempt, and it does NOT retry the op: standing Atlas starts a 700-doc walk that takes ~90s to
//    converge, so an immediate retry would answer off an empty census — which is worse than refusing,
//     because it looks like an answer.  Stand it, say so, say what it needs, and stop.
const STANDABLE = { Atlas: 'Ghost/L/Atlas.g', Lagoon: 'Ghost/L/Lagoon.g', Electrode: 'Ghost/L/Electrode.g' }
let auto_stood = null
let reply
for (let attempt = 1; ; attempt++) {
	reply = await sendAsk(ws, ask)
	const stuck = reply.control !== 'runner_ack' || reply.ok === false
	if (!stuck || attempt >= INSIST) break
	const why  = String(reply.result?.error ?? '')
	const want = /no A:(\w+) standing/.exec(why)?.[1]
	if (want && STANDABLE[want] && auto_stood !== want) {
		auto_stood = want
		console.error(`⇢ ${want} is not standing on ${TARGET.slice(0, 8)} (a tab reload drops the L ghosts) — standing it for you`)
		const st = await sendAsk(ws, { op: 'ghost_load', path: STANDABLE[want], stand: want })
		if (st.control === 'runner_ack' && st.ok !== false) {
			console.error(`⇢ stood A:${want}. The census walks in the background (~90s for the real corpus) — re-run when it has settled:`)
			console.error(`     node scripts/runner_ask.mjs lagoon lint --runner=${TARGET}   # 0 docs = still walking`)
			exitCode = 1
			ws.close()
			process.exit(exitCode)
		}
		console.error(`⇢ could not stand it: ${st.result?.error ?? st.error ?? 'no reply'}`)
	}
	console.error(`… runner ${TARGET.slice(0, 8)} ${reply.ok === false ? `refused (${reply.result?.error ?? 'busy'})` : 'silent'} — insisting ${attempt}/${INSIST}`)
	await new Promise(r => setTimeout(r, Number(process.env.RUNNER_INSIST_MS || 3000)))
}
// ── RE-COURT A WEDGED RUNNER (2026-09-09) ────────────────────────────────────────────────────────
//  A tab can answer `ping` instantly and still be unable to START anything — measured live the day the
//   Story ghosts were renamed under a running tab: `run` came back `{accepted:true, uid:null}` and no
//    phase ever appeared, on that tab, through a targeted reload.
//  The old broadcast court stumbled into a working tab by accident (only a tab that answered got the
//   corr).  Census courting is deterministic — its virtue — so it picks the SAME sick candidate every
//    time, and a human sees a CLI that reliably does nothing.
//  `accepted` with no `uid` is the signature, and it is available immediately, before the watch loop's
//   20s dead-clock ever starts.  So: drop that candidate and dispatch to the next one.
//  This is the same instinct the humdinger veto already has — *"a refusal RE-COURTS rather than
//   dead-ending"* — applied to the other way a courted tab turns out to be the wrong one.
//  Bounded by the candidate list and never re-tries a tab: worst case it tries each runner once and
//   then reports exactly what it reports today.
// ── A COURTED TAB THAT THEN ANSWERS NOTHING (2026-09-09, measured: 2 invocations in 3) ────────────
//  The broadcast court commits to whichever tab acked first, and an ack proves almost nothing: a
//   humdinger music page holding the shared `runner` seat answers `role:'runner'` too (the fact
//    `isRunner` above already calls useless).  Address THAT by prepub and the relay's own-door rule
//     drops it on the station socket — so the ask times out and the CLI reports "runner not connected"
//      while two healthy runners sit beside it.  The humdinger veto does not save us here: it is
//       skipped for read-only ops, which is most of them.
//  So do for a silent target what we already do for a wedged one: drop it and try the next tab that
//   answered.  Bounded by the acks we actually have, never re-tries a tab, and costs nothing when the
//    first pick was right (the overwhelmingly common case).
if (reply.control !== 'runner_ack' && !runnerSel && !playerSel) {
	// WHERE THE ALTERNATES COME FROM, and why not from the court.  A broadcast court comes home with
	//  exactly ONE ack however many tabs answered — the relay spends our corr on the first — so there is
	//   never a second candidate sitting in `courtCands` to try.  (I built the re-court on that
	//    assumption first, and it never fired once in 8 runs.  The one-ack rule is written down three
	//     times in this file; I still coded past it.)
	//  The stochastic sweep is the road that CAN enumerate — it is what `runners` prints and what the
	//   humdinger veto already falls back to — so use it, and only here, on the failure path, where its
	//    couple of seconds cost nothing against an invocation that was about to report a lie.
	let others = courtCands.filter(p => p !== TARGET)
	if (!others.length) {
		const rs = ((await census({ classify: true })) ?? []).filter(f => f.role === 'runner' && f.pub !== TARGET)
		others = rs.map(f => f.pub)
	}
	for (const next of others) {
		console.error(`⇢ ${String(TARGET).slice(0, 8)} acked the court then answered nothing — trying ${next.slice(0, 8)}`)
		TARGET = next
		reply = await sendAsk(ws, ask)
		if (reply.control === 'runner_ack') { try { writeFileSync(STICKY_PATH, TARGET + '\n') } catch { /* stash is best-effort */ } ; break }
	}
}
if (op === 'run' && reply.control === 'runner_ack' && reply.ok !== false && !reply.result?.uid && courtCands.length > 1) {
	const others = courtCands.filter(p => p !== TARGET)
	for (const next of others) {
		console.error(`⇢ ${TARGET.slice(0, 8)} accepted '${arg}' but started nothing (uid:null — a wedged tab) — re-courting ${next.slice(0, 8)}`)
		TARGET = next
		reply = await sendAsk(ws, ask)
		if (reply.control === 'runner_ack' && reply.ok !== false && reply.result?.uid) {
			try { writeFileSync(STICKY_PATH, TARGET + '\n') } catch { /* stash is best-effort */ }
			break
		}
	}
	if (!reply.result?.uid) console.error(`⇢ every runner-door tab accepted and started nothing — the Books may be unloadable on this build (a rename under a live tab does exactly this)`)
}
if (reply.control !== 'runner_ack') { console.error(`✗ ${op}: ${reply.error ?? 'no reply'}`); exitCode = 1 }
else if (op === 'snap' && reply.result?.got_snap) {
	console.error(`snap: Step ${reply.result.n} ok=${reply.result.ok} dige=${reply.result.dige}`)
	process.stdout.write(reply.result.got_snap.endsWith('\n') ? reply.result.got_snap : reply.result.got_snap + '\n')
} else if (op === 'minisnap' && reply.result) {
	const r = reply.result
	console.error(`minisnap ${r.pointers} — ${r.nodes} lines${r.cut ? ' ⚠ CUT' : ''}`)
	if (r.diff !== undefined) process.stdout.write((r.diff.endsWith('\n') ? r.diff : r.diff + '\n'))
	else process.stdout.write((r.snap ?? '').endsWith('\n') ? r.snap : (r.snap ?? '') + '\n')
} else if (op === 'supervisor' && reply.result?.stood != null) {
	// THE SUPERVISOR'S OWN SCREEN, on a terminal.  Same rows, same order, same marks the Butler and
	//  the cell draw — the model judged them (Supervisor_lines) and nothing here re-decides.  The one
	//   thing added is `fn`, the probe method: a face may never show it (that would make the Butler
	//    the panel), and this IS the panel's audience, so it is the first thing you want when a row
	//     reads `unknown`.
	const r = reply.result
	if (!r.stood) { console.log('supervisor: NO ROSTER on this tab — nothing has registered a watch'); }
	else {
		// HOW STALE IS ALL OF THIS.  Every row below is what the last read left behind, so without this
		//  a roster frozen at boot prints exactly like one read a second ago — all green, all lies.
		const ago = r.read_ago
		const fresh = ago == null ? ''
			: ago < 0 ? '  ⚠ NEVER READ — the heartbeat has not run on this tab'
			// 15s, against a 2s beat: comfortably past a slow pass, nowhere near a wedged drive.
			: ago > 15000 ? `  ⚠ STALE: last read ${(ago / 1000).toFixed(0)}s ago — every row below is a photograph`
			: `  (read ${(ago / 1000).toFixed(1)}s ago)`
		console.log(`supervisor: ${r.watches} watch(es) — arrived:${r.arrived}  loud:${r.loud}  amiss:${r.amiss}${fresh}${r.humdinger ? '  (humdinger — an end-user room, an arrival is declared here)' : '  (not a humdinger — no arrival is declared on this tab, so arrived:none is CORRECT)'}`)
		// THE BOOT WATERFALL, when there is one — every claim that came true, in the order it came
		//  true, timed from page start.  This is the efficiency ledger (the owner 2026-08-10: *"it just
		//   needs lots of timestamped tracing and analysis"*), and reading it in TURN order rather than
		//    arc order is the point: the arc says what depends on what, this says what actually took
		//     the time.  Gaps between consecutive rows are the legs worth attacking.
		const won = r.lines.filter(l => l.won).sort((a, b) => a.won - b.won)
		if (won.length) {
			console.log(`  ── boot waterfall (ms from page start) ──`)
			let prev = 0
			for (const l of won) {
				const gap = l.won - prev
				console.log(`     ${String((l.won / 1000).toFixed(1)).padStart(7)}s  ${gap > 1000 ? `+${(gap / 1000).toFixed(1)}s` : '      '}  ${l.key}`)
				prev = l.won
			}
			console.log('')
		}
		for (const l of r.lines) {
			const clock = l.waiting && l.left ? `  ${l.left}s`
				: (l.won ? `  ${(l.won / 1000).toFixed(1)}s` : '')
			console.log(`  ${l.mark} ${l.arrival ? '⚑ ' : ''}${l.sentence}${clock}`)
			if (l.note) console.log(`      ${l.note}`)
			// ADVICE ONLY WHEN WE ACTUALLY GAVE UP — the same gate the Butler applies (`gaveup &&
			//  advice`).  `advice` is stamped when an expectation is ARMED and is never cleared when the
			//   claim comes good, so printing it unconditionally put "no friend is online — you can
			//    listen to your own music" under a green "a friend came online ✓".  The instrument
			//     disagreeing with the screen is worse than no instrument.
			if (l.gaveup && l.advice) console.log(`      ↳ ${l.advice}`)
			console.log(`      · ${l.key}  kind:${l.kind} stage:${l.stage} verdict-tone:${l.tone}${l.met ? ' met' : ''}${l.gaveup ? ' GAVE-UP' : ''}${l.orphan ? ' ORPHAN (its world was torn down — not a fault)' : ''}  fn:${l.fn}${l.where ? `  in:${l.where}` : ''}`)
		}
		// the DIALS — the overall states, which is what a face shows when nothing is wrong.  Kept
		//  under the watches and visually quieter: a dial is never an alarm, it is the readout.
		for (const d of (r.dials ?? [])) {
			console.log(`  ${d.mark} ${d.label}${d.reading ? ' — ' + d.reading : ''}`)
			console.log(`      · ${d.key}  state:${d.state} stage:${d.stage}${d.orphan ? ' ORPHAN (its world was torn down — not a fault)' : ''}  fn:${d.fn}${d.where ? `  in:${d.where}` : ''}`)
		}
		// the prefs FIRST when one is on: a silenced surface explains a report better than any row below
		//  it, and `guts` is per-origin (the House stash is Dexie), so it changes every tab at once.
		for (const p of (r.prefs ?? [])) {
			if (p.on) console.log(`  ⚑ pref ${p.key} is ON — per-browser, not per-tab; turn it off in the Supervisor panel (▦)`)
		}
		if (r.notices.length) {
			console.log(`  — what turned, oldest first:`)
			for (const ev of r.notices) console.log(`      ${ev.sentence}${ev.n > 1 ? ` ×${ev.n}` : ''}`)
		}
	}
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
	for (const p of r.piers) {
		console.log(`  ${p.mutual ? '⇄ MUTUAL' : '→ one-way (half-seal)'}  ${p.friendly ? p.friendly + ' ' : ''}${p.pub}  grants:[${p.grants.map(g => `${g.by}→${g.to}`).join(', ')}]`)
		// the offer ledger — why music is or is not moving over a seal that looks perfect.
		//  `no transport route` is the loud one: the friendship survived a reload and the link did not.
		// ABSENT ≠ NULL, and the difference matters more than the reading.  A tab still running an
		//  older Lies answers without the field at all (JSON drops `undefined`), and printing "no
		//   transport route" for that would be the instrument inventing the very bug it was built to
		//    find.  `null` is the tab SAYING there is no route; missing is the tab not knowing the
		//     question.
		const rt = p.route
		if (rt === undefined) console.log(`      (this tab predates the offer ledger — reload it to read one)`)
		else if (rt === null) console.log(`      ⚠ no transport route — sealed but unspeakable (Swarm_station_routes never re-minted it)`)
		else {
			const s = ms => ms == null ? 'never' : (ms < 1000 ? 'now' : Math.round(ms / 1000) + 's ago')
			const gate = rt.heard_ago == null || rt.heard_ago >= 20000 ? '  ⚠ PRESENCE GATE SHUT (offers skipped)' : ''
			console.log(`      heard ${s(rt.heard_ago)}${gate} · offered ${s(rt.offered_ago)} · caster:${rt.caster} rx:${rt.rx} peer_era:${rt.peer_era ?? '—'}`)
			if (rt.offered_mark) console.log(`      mark ${rt.offered_mark}   (station_era:peer_era:stock:tour)`)
		}
	}
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
	//  stated outright: duplicate %Theirs homes for one pub all resolve to ONE shelf, so every reader
	//   that loops homes counts that crate once per duplicate.  `recs > distinct_ids` is the other leak
	//    (the same track standing twice in the tree) — they are different bugs and look identical in a total.
	if (r.crate_census) {
		const c = r.crate_census
		const dupHomes = c.them_homes > c.them_pubs
		console.log(`\ncrates: ${c.them_homes} %Theirs home(s) over ${c.them_pubs} pub(s)${dupHomes ? `  ⟵ DUPLICATE HOMES — one crate counted ${c.them_homes}×` : ``}, ${c.self_homes} %Mine`)
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
	if (r.resident_snap) { writeFileSync('/tmp/runner_resident.snap', r.resident_snap); console.error(`  RESIDENT (radio) world snap → /tmp/runner_resident.snap  (${r.resident_snap.length} bytes) — grep it for Radio/Theirs`) }
} else if (op === 'electrode' && reply.result && !reply.result.error) {
	const r = reply.result
	const name = (x) => x == null ? '∅' : String(x)
	if (Array.isArray(r.hangs)) {
		console.log(`hangs: ${r.hangs.length} open frame(s), oldest first`)
		for (const h of r.hangs) console.log(`  ${String(h.age_ms).padStart(8)}ms  ${h.m}${h.async ? '  (async)' : ''}  ← ${name(h.from)}`)
	} else if (Array.isArray(r.film)) {
		console.log(`film: last ${r.film.length} marks (Δ = ms since previous mark)`)
		let prev = null
		for (const e of r.film) {
			const d = prev == null ? 0 : e.t - prev
			prev = e.t
			console.log(`  +${String(d).padStart(6)}ms  ${e.ev} ${e.m.padEnd(34)} #${e.id}${e.from ? ' ← ' + e.from : ''}${e.ms != null ? '  ' + e.ms + 'ms' : ''}${e.async ? ' async' : ''}${e.how === 'throw' ? ' THREW' : ''}`)
		}
	} else if (Array.isArray(r.never_ran_top)) {
		console.log(`join: ${r.ran_methods} methods ran as callers (${r.unknown_callers} callers Atlas has no def for) · declared pairs ${r.declared_pairs}, ran ${r.pairs_ran} → coverage ${r.coverage}% · never-ran ${r.never_ran} · undeclared (dynamic) ${r.undeclared} · Atlas ${r.atlas_docs} docs / ${r.atlas_defs} defs the tap can see`)
		if (r.never_ran_top.length) {
			console.log('  declared but never ran this session (via → callee):')
			let last = null
			for (const x of r.never_ran_top) {
				if (x.via !== last) { console.log(`    ${x.via}${x.doc ? '  (' + x.doc + ')' : ''}`); last = x.via }
				console.log(`        ↛ ${x.callee}`)
			}
		}
		if (r.undeclared_top.length) {
			console.log('  measured but not declared (dispatch the static walk cannot follow):')
			for (const x of r.undeclared_top) console.log(`    ${String(x.n).padStart(6)}  ${x.from} → ${x.to}`)
		}
	} else if (Array.isArray(r.by_n)) {
		console.log(`electrode: ${r.armed ? 'ARMED' : 'disarmed'}${r.coated != null ? ' (coated ' + r.coated + ')' : ''} — ${r.calls} calls over ${r.flows} flows, ${r.marks} marks in the ring (${r.dropped} dropped), ${r.open} open`)
		if (r.by_n.length) {
			console.log('  hottest by count:')
			for (const x of r.by_n) console.log(`    ${String(x.n).padStart(7)}  ${name(x.from).padEnd(34)} → ${x.to}  (${x.ms}ms)`)
			console.log('  hottest by time:')
			for (const x of r.by_ms) console.log(`    ${String(x.ms).padStart(7)}ms  ${name(x.from).padEnd(34)} → ${x.to}  ×${x.n} max ${x.max}ms${x.async ? ' async ' + x.async : ''}`)
		}
	} else console.log(`electrode: ${JSON.stringify(r)}`)
} else if (op === 'lagoon' && reply.result && !reply.result.error && reply.result.atlas != null && reply.result.defs) {
	// seek — the unified answer, printed in the seeker's own order.  The header says which censuses
	//  replied, because a partial answer that looks whole is the silent-empty law one layer up.
	const r = reply.result
	// STANDING IS NOT THE SAME AS ANSWERING.  A runner has a `w:Lies` but never mounts a searchbar, so
	//  its Stemdex is empty — and "stemdex" in this header would claim a reading that contributed
	//   nothing.  Say which state it is in; a census that answered nothing should look different from
	//    one that answered.
	const dex = !r.stemdex ? 'stemdex NOT standing'
		: !r.total ? 'stemdex standing but UNINDEXED here (0 docs — nothing has scanned on this tab)'
		: `stemdex ${r.done}/${r.total} docs`
	console.log(`seek "${r.q}" — ${r.atlas ? '◈ atlas' : '◈ atlas NOT standing'} · ${dex}`)
	if (r.families?.length) {
		console.log(`\n  ◈  families — the larger objects (${r.families.length})`)
		console.log('    ' + r.families.map(f => `${f.head ?? f.stem}·${f.defs}`).join('   '))
	}
	// a `doc:` scope that lands on ONE document answers with its SHAPE first — the beadchain — and the
	//  defs list below it is then the same content flattened, which is worth seeing both ways.
	if (r.beads) {
		const b = r.beads
		console.log(`\n  ◆  ${b.doc} — ${b.lines} lines · ${b.beads} bead(s) · ${b.defs} def(s)${b.loose ? ` · ${b.loose} outside every bead` : ''}`)
		for (const c of b.chain) {
			const pad = '    ' + '  '.repeat(c.depth ?? 0)
			if (c.kind === 'region') console.log(`${pad}◆ ${c.label}${c.defs ? `   (${c.defs})` : ''}`)
			else console.log(`${pad}· ${String(c.label).padEnd(36 - pad.length)} :${c.line}`)
		}
	} else if (r.beads_ambiguous) {
		console.log(`\n  ◆  ${r.beads_ambiguous} docs match that doc: prefix — narrow it for a beadchain`)
	}
	const sect = (title, rows, fmt) => { if (!rows?.length) return
		console.log(`\n  ${title}  (${rows.length})`)
		for (const x of rows.slice(0, 40)) console.log('    ' + fmt(x))
		if (rows.length > 40) console.log(`    … ${rows.length - 40} more`) }
	// ⚗ marks a Testing doc — the same predicate as src/lib/L/testing.ts (copied: an .mjs can't import $lib)
	const T = p => /Testing\.g$/.test(p ?? '') ? '⚗ ' : '  '
	sect('ƒ  methods', r.defs, d => `${T(d.doc)}${String(d.name).padEnd(34)} ${d.doc}:${d.line}${d.from === 'stemdex' ? '   (stemdex only)' : ''}`)
	if (r.mentions?.length) sect(`¶  prose that names \`${r.mentions_of}\``, r.mentions, m => `${T(m.doc)}${m.doc}:${m.line}`)
	sect('%  properties', r.props, p => `${T(p.doc)}${String(p.name).padEnd(34)} ${p.doc}:${p.line ?? ''}`)
	sect('≈  text', r.texts, t => `${T(t.doc)}${String(t.name).padEnd(34)} ${t.doc}:${t.line ?? ''}`)
	if (!r.defs.length && !r.props?.length && !r.texts?.length && !r.families?.length) console.log('  nothing')
} else if (op === 'lagoon' && reply.result && !reply.result.error && reply.result.chain) {
	// beads — one document as its own shape.  Printed as a CHAIN: file order, indented by region
	//  depth, region lines carrying how much of the file they hold.  No arrangement is invented; an
	//   order and an indent are the two things the corpus actually states (Lagoon_todo leg 4).
	const r = reply.result
	console.log(`beads: ${r.doc} — ${r.lines} lines · ${r.beads} bead(s) · ${r.defs} def(s)${r.loose ? ` · ${r.loose} outside every bead` : ''}`)
	for (const c of r.chain) {
		const pad = '  '.repeat(1 + (c.depth ?? 0))
		if (c.kind === 'region') console.log(`${pad}◆ ${c.label}${c.defs ? `   (${c.defs})` : ''}`)
		else console.log(`${pad}· ${String(c.label).padEnd(38 - pad.length)} :${c.line}`)
	}
} else if (op === 'lagoon' && reply.result && !reply.result.error && reply.result.errands) {
	// the day's research trail, read back off the Aside — what you went in there to look at.
	//  ↩ is where you came from; ×N is how many times you returned; ⌦ marks a path the census cannot
	//   place, which is HISTORY (the visit happened) and never presented as rot.
	const r = reply.result
	console.log(`errands — ${r.total} moment(s) across ${r.days.length} day(s)${r.gone ? ` · ${r.gone} doc(s) since renamed or gone` : ''}${r.atlas ? '' : ' · no Atlas standing, so nothing is checked'}`)
	let day = ''
	for (const m of r.errands) {
		if (m.day !== day) { day = m.day; console.log(`\n  ▤ ${day}`) }
		console.log(`    ${String('×' + m.visits).padStart(4)}  ${m.about ?? '(no label — an older moment)'}`)
		for (const d of m.docs) console.log(`          ${d.gone ? '⌦' : ' '} ${d.doc}${d.points.length ? `  ${d.points.join(' · ')}` : ''}`)
		if (m.from_waft) console.log(`           ↩ from ${m.from_waft} — ${m.from_tail}`)
	}
} else if (op === 'lagoon' && reply.result && !reply.result.error && reply.result.figurines) {
	// the figurines — who is well connected.  callers = DISTINCT measured callers (the size), declared =
	//  distinct bodies Atlas says call it, fan = distinct callees, ⇡ = top-most (only ever entered from
	//   outside the coats).  An un-armed tally is an honest zero, not a refusal — say so.
	const r = reply.result
	console.log(`figurines — ${r.ran} methods ran · ${r.tops} top-most · max ${r.max_callers} distinct callers${r.armed ? '' : '   ⚠ electrode NOT armed — runner_ask electrode arm, then do something'}`)
	// a census that cannot place most of what ran is almost always one a Book left aimed at its
	//  fixture (Lagoon_todo §2.5b) — say it once here, not once per row
	if (r.unjoined && r.unjoined * 2 > r.ran) console.log(`  ⚠ ${r.unjoined}/${r.ran} ran methods have no def in Atlas (census holds ${r.atlas_docs} doc${r.atlas_docs === 1 ? '' : 's'}) — aimed at a fixture?  ghost_load Ghost/L/Atlas.g --stand=Atlas --fresh`)
	const T = p => /Testing\.g$/.test(p ?? '') ? '⚗ ' : '  '
	for (const f of r.figurines) {
		const bar = '█'.repeat(Math.max(1, Math.round(f.dose * 12))).padEnd(12)
		console.log(`  ${bar} ${f.top ? '⇡' : ' '} ${T(f.doc)}${String(f.name).padEnd(34)} ←${String(f.callers).padStart(3)} (decl ${f.declared})  →${String(f.fan).padStart(3)}  ×${String(f.n).padStart(5)} ${String(f.ms).padStart(6)}ms  ${f.doc ? `${f.doc}:${f.line}` : '(no def in Atlas — a House method or by-name dispatch)'}`)
	}
} else if (op === 'lagoon' && reply.result && !reply.result.error && reply.result.queue) {
	// rotwork — the queue, printed as a round of visits rather than a list of links.  Doc, then its
	//  items with a proposed fix where the census could compute one, then the exit it leans to.
	const r = reply.result
	console.log(`rotwork: ${r.rot_items} rotted pointer(s) over ${r.docs_with_rot} doc(s) — ${r.to_fix} to FIX, ${r.to_obsolete} that look STALE (retire to spec/history/)`)
	for (const g of r.queue) {
		console.log(`\n  ${g.exit === 'obsolete' ? '⌦ STALE?' : '✎ FIX   '}  ${g.doc}  — ${g.n} pointer(s)`)
		for (const it of g.items) {
			console.log(`      :${String(it.line).padEnd(5)} ${it.kind.padEnd(4)} ${it.target}`)
			console.log(`             ${it.why}${it.fix ? `   →  try  ${it.fix}` : ''}`)
		}
	}
	if (r.docs_with_rot > r.queue.length) console.log(`\n  … ${r.docs_with_rot - r.queue.length} more doc(s) — --k=N for a longer round`)
} else if (op === 'lagoon' && reply.result && !reply.result.error
           && (reply.result.sect_links != null || reply.result.sworn_links != null)) {
	// the two LINT-shaped verbs print as a report, not a JSON wall — `lint` can carry hundreds of rot
	//  rows and `oaths` a row per Book.  Everything else the reader answers stays raw JSON below (a
	//   defs|families|mentions reply is a list a human greps, and shaping it would only lose fields).
	const r = reply.result
	const cap = (a, n) => a.slice(0, n)
	if (r.sect_links != null) {
		console.log(`lint: ${r.docs} docs · file:line ${r.file_links} (${r.missing.length} missing, ${r.beyond_eof.length} past EOF) · § ${r.sect_links} — ${r.sect_links - r.sect_self} doc-qualified (${r.sect_nodoc.length} no such doc, ${r.sect_gone.length} no such section), ${r.sect_self} bare (referent is prose — not linted) · orphan defs ${r.orphans_total}`)
		if (r.sect_gone.length) {
			// the NEW signal, and the reason § was worth collecting: the doc is alive and reads fine,
			//  but the section it points at has been renumbered, merged or dropped.
			console.log(`  § pointing at a section that is gone (live doc, dead anchor):`)
			for (const x of cap(r.sect_gone, 40)) console.log(`    ${x.doc}:${x.line}  →  ${x.target} §${x.sect}`)
			if (r.sect_gone.length > 40) console.log(`    … ${r.sect_gone.length - 40} more`)
		}
		if (r.sect_nodoc.length) {
			console.log(`  § pointing at a doc nothing rosters (moved to history/, renamed, or never was):`)
			for (const x of cap(r.sect_nodoc, 20)) console.log(`    ${x.doc}:${x.line}  →  ${x.target} §${x.sect}`)
			if (r.sect_nodoc.length > 20) console.log(`    … ${r.sect_nodoc.length - 20} more`)
		}
	} else {
		console.log(`oaths: ${r.tocs_read} toc(s) read over ${r.books} Book(s), ${r.oaths} declared assertion(s) · Book: links ${r.book_links} (${r.book_gone.length} gone) · «sworn» links ${r.sworn_links} (${r.sworn_ok.length} land, ${r.sworn_gone.length} gone)`)
		for (const x of cap(r.sworn_ok, 40))   console.log(`    ✓ ${x.doc}:${x.line}  «${x.slug}»  → Book:${x.book}`)
		for (const x of cap(r.sworn_gone, 40)) console.log(`    ✗ ${x.doc}:${x.line}  «${x.slug}»  — no Book declares it`)
		for (const x of cap(r.book_gone, 40))  console.log(`    ✗ ${x.doc}:${x.line}  Book:${x.target}  — no such Book`)
	}
} else if (op === 'console' && reply.result && Array.isArray(reply.result.lines)) {
	// the live tab's console ring — the raw log/warn/error a human reads in DevTools, over the wire.
	//  Each line prefixed with a wall-clock time + level, so ordering + severity read at a glance.
	const r = reply.result
	console.error(`console: ${r.returned}/${r.total} line(s)${ask.grep ? ` matching ${JSON.stringify(ask.grep)}` : ''}${ask.tail ? ` (tail ${ask.tail})` : ''} from ${TARGET.slice(0, 8)}`)
	for (const c of r.lines) { conSeen.add(`${c.t}|${c.line}`); console.log(`${fmtConLine(c)}`) }
	if (!flags.has('--follow') && !r.total) console.error('  (ring empty — nothing has logged since this tab booted; is it a fresh reload?)')
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

// --follow (console): keep polling the ring, printing only lines we have not printed yet, until Ctrl-C.
//  A read-only tail -f over the relay.  Same grep/tail as the first read (tail bounds each poll's window,
//   so a chatty tab won't reprint its whole ring every second — dedup by t|line does the rest).
if (flags.has('--follow') && op === 'console' && reply.control === 'runner_ack') {
	console.error('  … following (Ctrl-C to stop)')
	const gapMs = Number(process.env.RUNNER_CONSOLE_FOLLOW_MS || 1000)
	for (;;) {
		await new Promise(r => setTimeout(r, gapMs))
		const s = await sendAsk(ws, ask)
		if (s.control !== 'runner_ack' || !Array.isArray(s.result?.lines)) continue   // a missed poll is not fatal in follow
		for (const c of s.result.lines) {
			const key = `${c.t}|${c.line}`
			if (conSeen.has(key)) continue
			conSeen.add(key)
			console.log(fmtConLine(c))
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
