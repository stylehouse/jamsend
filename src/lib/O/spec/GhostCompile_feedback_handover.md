# ghost-compile / channel feedback — handover

A continuation brief for the next agent. Arc, bombs, next move — not a changelog.
Pairs with `Editron.md` §3 (the request half) and [[ghost-compile]], [[ttlilt-not-a-keepalive]],
[[compile-boomerang-latency]] in memory.

## Destination

Make `ghost-compile` and the editor↔runner channel **tell the truth about delivery**. The
original sin: the CLI sent a frame, closed the socket, and `exit 0`'d — reporting a success it
never confirmed. A dead/half-open editor should be **legible** (the CLI says why; the runner
*shows* it), not a silent `0 confirmed` mystery.

Framing that emerged this session: **claude (the CLI) is just another peer.** The relay is a peer,
the runner is a peer, the CLI joins briefly to ask for a compile. They all want modelling as
endpoints (the `%Aim` Waft — see spec/Lens_handover.md) with an UP/DOWN and a log of what they're
doing. The whole feedback effort is one instance of "make every peer legible."

## The state in one line — TURNING POINT

**The loop now CLOSES, correctly: `ghost-compile` → `✅ gc_ack done @ <new dige>`, live-verified.**
The compile-never-fired wedge AND the one-round lag are both fixed (see RESOLVED below). What's left is
not correctness — it's **speed**, and speed is now **acceptable**: a later session settled the channel to
**~2–5s wall** (down from ~5.3s, originally ~18s), and the human's call on it is **"is ok."** So the
latency swamp (`Editron.md` → THE LATENCY SWAMP) is **demoted from blocker to OPTIONAL**: the cost is still
channel/req-pacing dead-air (not the compiler — proven fast), and a bounded self-pump is a ready cheap win
*if* 2–5s ever bites — but **the road ahead is Peeroleum**, not more channel-shaving. Don't re-enter the
swamp's masterminding as if it's urgent; it isn't anymore.

## This session (the turning point)

- **Compile-never-fired wedge — fixed.** `req:Languish` is eternal, so a re-provide of an already-open
  dock never re-armed `req_compile`. `Lang.e_Lang_dock_content`'s force_active branch now compiles itself.
- **One-round lag — fixed (the load-bearing one).** It compiled the PREVIOUS edit because `Lang_compile_dock`
  read `dock.c.state` (the editor's *display buffer*), and the buffer's reseat into CodeMirror is async, so
  it still held the prior text. Decoupled: the compile source is now a parameter
  (`Lang_compile_dock(w,dock,stateOverride?)`) built straight from the fresh disk text by
  `Lang_compile_source_state` (reuse the editor's config + swap doc, or `lang()` build when no editor — the
  DOM-free bridge). Never touches `dock.c.state` (point-nav/region-fold/offsets keep it).
- **Headless harness — `scripts/LakeRace.*`** ([[lakerace-compiler-fast]]): emulates the CLI ghost_compile on
  the REAL Peeroleum.g, in node. Proves the lag dead (warm+cold+the real `dock_content` recv handover all emit
  the NEW dige) and that the compiler is ~0.07ms/line (Peeroleum.g ~30ms). `node scripts/LakeRace.run.mjs`.
- **Folklore corrected** ([[hmr-remixes-ghost-methods]]): ghost methods DO re-mix on HMR (`ghostsHaunt →
  all_House`); bomb #6's "hard-reload after editing a ghost" is wrong. Only construction-captured fn *refs*
  go stale. (Confirmed in-app: the lag fix took effect with no hard-reload.)

## Landed (committed — see "Working tree" below)

- **`#2` editor ack `{started|done(dige)|error(errors)}`** — `Lies_ghost_compile_ack` sends a raw
  `control` frame (NOT a Peeroleum envelope; the CLI is no peer) down the editor socket; the relay
  corr-routes it back via an `ackBack` map (the CLI has no addr). `started` fires in
  `Lies_ghost_compile_recv`; `done`/`error` fire from `Lang_drain_compile_settles` (off the shared
  **`H.c.gc_acks`** — NOT `w.c`: recv runs on `w:Lies`, the drain on `w:Lang`, only the House
  bridges them; the entry also stashes the channel `w:Lies` so the reply rides the socket-bearing w).
  **Live-verified end-to-end: `started` AND `done`/`error` now reach the CLI** — the wedge that swallowed
  `done` (the missing settle) is RESOLVED. The CLI settles `✓ compiled @ <dige>` on the `done` ack; that is
  the reliable confirm path (the ground-truth dige poll stays unreliable per bomb 3, so don't lean on it).
- **`#1` relay `undeliverable`** — `routeFromBrowser` returns `'local'|'bridge'|'dropped'`; on a
  dropped `ghost_compile` the asking socket gets `{control:'undeliverable',corr,path}`. Clean-gone
  editor → CLI settles `no-editor` at once (no 12s wait).
- **`#1-real` half-open prune** — a WS ping/pong heartbeat (`relay.ts`, 15s, `isAlive`/`pong`):
  a missed round → `ws.terminate()` → close-handler unbinds it from `locals`, so `deliverLocal`
  (still `readyState===OPEN`-based) stops lying. Also heals the editor↔runner leg (terminating a
  half-open editor trips its browser-side auto-reconnect).
- **Relay visibility** — `relay.ts` now logs `browser DISCONNECTED addr=… code=…` (was silent), and
  the CLI **binds an ephemeral addr** `cli-<prepub>-<stamp>` + prints `(as cli-…)`, so it's a named,
  logged participant — first step of "claude is a peer". Reply stays corr-routed (more robust than
  addr for concurrency).
- **Channel reliability (the unblocker for the *feedback*, LiesLies)** — the liveness watchdog was
  force-closing the socket *mid-compile* on a stale-`last` reading (self-perpetuating flap that tore
  the channel down during ghost_compile); now it measures silence by `max(last, last_heard)`.
  `last_heard` (stamped on any inbound frame in `Lies_pong`) keeps the Runner Brink honestly live.
- **In-UI logs** — `Lies_relay_note` rings consumer-side events (reconnect-reason, `🔄 compiling`)
  onto `w.c.relay_log`, `important`/60s; Relay Brink renders them (routine 5s). `Tribunal.g`'s carrier
  `note()` rings SEND/RECV/OPEN/CLOSE.

## THE BLOCKER — RESOLVED (kept for the mechanism)

> Fixed this session: the wedge below was the eternal-`req:Languish` no-re-arm + the one-round lag, both
>  now closed (see "This session" above). The diagnosis is kept because it still explains how the compile
>   pipeline settles — and because the SAME quiescence it describes is now the latency swamp (Editron.md).

`ghost-compile` lands `started`, the dock force-loads and **refreshes** (`Text.dige == disk_dige`,
confirmed in the snap), and then **nothing compiles.** Both diagnostic lines I left in
`Lang_drain_compile_settles` (`✅ gc_ack done` / `⚠ compile settled … no gc_ack`) stay silent →
**`Lies_compile_settled` never fires.** The snap shows it directly:

```
Change/ +backend,dige:62463  +storage,dige:62463      ← source advanced
        compile,dige:b9c1c,secs=0.057,dim,pending      ← STUCK on the old dige, pending never clears
```

Mechanism (the bomb): `job.sc.pending` is set by `Lang_compile_dock` and cleared **only** by
`req_compiled_is_settled` ← `Lies_compile_settled`. When that settle doesn't fire, `pending` sticks,
`req:compile` stays gated, and — per `LiesCortex`'s own comment (~:178-195) — **`e_Lang_compile`
then skips every later edit on the stuck pending.** So one missed settle wedges all future compiles.
`req_compile` has a 150ms trickle re-pump (`Lang.svelte:1905`) that shouts `🔥 req:compile trickle
still spinning` while it waits — **the decisive next-run question is whether that 🔥 log appears**:
- **yes** → `req:compile` is alive but `pending` never clears → the gen_write→Codebit→settle chain
  upstream is broken (instrument `e_Lies_compiled` entry + each `Lies_compile_settled` fire).
- **no** → `req:compile` already `finish`ed with `pending` set / never re-armed → nothing re-checks.

**Crucially: the editor's stuck `pending` and ghost-compile's missing `done` are the SAME event not
firing.** Fix the settle and you fix both. This wedges from the editor alone too — it is not
ghost-compile-specific.

## Bombs (lose these and you'll re-derive them the hard way)

1. **`deliverLocal` is half-open-blind** (`relay.ts:112-121`): `readyState===OPEN` is true for a
   TCP-half-open zombie. Mitigated by the #1-real heartbeat (prunes them), not by changing
   `deliverLocal` itself.
2. **The CLI timeout is load-bearing** — the only catch for the half-open case where neither
   `undeliverable` nor an ack arrives (the heartbeat takes up to ~30s; the CLI gives up at 12s).
3. **dige-normalization mismatch — the dige-flip poll is effectively DEAD.** The CLI hashes the disk
   bytes (`readFileSync(f,'utf8')`); the editor's compile hashes the CodeMirror buffer
   (`state.doc.sliceString(0)`). Same edit → different dige (e.g. `faf14…` vs `9b10f…`, both the
   *Chumblesworth* edit) — almost certainly a trailing-newline/EOL difference. So `pollServed` looks
   for a dige the served `.go` will never contain. **The ack is the only reliable path to `✓`** — which
   is *why* the settle/`done` fix matters; the poll can't bail us out. Worth normalising both sides
   (canonical trailing newline) so content-addressing actually agrees.
4. **No standalone compiler** — `ghost-compile` is relay→**live editor** only. You cannot
   headless-verify a `.g`; you need an editor tab with the dock open.
5. **Editor rides the FROZEN `pinned_stable` spine** — `.g` edits reach the *runner* via
   ghost-compile; the *editor* only after `cp gen/N → pinned_stable`. So `Tribunal.g` edits (the
   carrier `note()` etc.) need a recompile + promote to go live in the editor.
6. **Ghost-method edits may not HMR onto the live House** — `LiesLies`/`LangCompiling` are eatfunc'd
   onto a persistent House at construction; Svelte HMR can swap the component without re-mixing the
   methods. **Hard-reload the editor tab** after editing a ghost, or you'll test stale methods (this
   ate time — `started` worked in both the old `w.c` and new `H.c` versions, hiding which was live).
7. **Two live editor sockets** seen in testing — `deliverLocal('editor')` fans the request to both,
   both `recv`, both `started`-ack → "one out, two back". Cosmetic (CLI dedupes by `corr`; `done`
   sends once). Both bind `addr=editor`, so they're indistinguishable in logs. Likely two tabs or an
   inner compiler-Lies; check for a stray editor tab.
8. **Never bump `w.version` per frame** — the `relay_log` ring is poll-on-tick (the run_phase wedge).

## Next moves — the road ahead is PEEROLEUM (latency parked)

The human's call: compiles are ~2–5s and **"is ok"**, so **get on with Peeroleum and the actual road ahead**
 ([[peeroleum-bootstrap]], `Peeroleum_handover.md`) — not more channel-shaving. Everything below is **parked
  as optional**, kept so the design isn't lost, not because it's the next thing.

Two design musings the human floated — capture so they survive; neither is decided:
 - **Editron: an extra "big step"** that brackets the WHOLE timeframe of *the human asking an AI to do a test
   manipulation → it actually landing* (the ghost-compile round-trip as ONE traced Story step), so that loop's
    latency/correctness is a recorded step-snap, not transient channel noise. Aligns with the swamp's "durable
     markers, not transient state" doctrine; the marker would live in the Editron Book.
 - **`reqyoncile` should be "the coming back."** Hypothesis: in most cases the req reconcile already does the
   return/settle; the dead-air is exactly the hops where it DOESN'T re-pump (no event wake; a ttlilt is one-shot,
    [[ttlilt-not-a-keepalive]]). "It shouldn't be fragile" → find the hops where reqyoncile is NOT what brings
     the pipeline back and make it so (or give them an event wake). Same diagnosis as #2/#3 below, framed as
      *reqyoncile owns the return everywhere.*

**If/when the latency is revisited** (`Editron.md` → "THE LATENCY SWAMP"; all dead-air between req hops,
 heartbeat round-trips of 3.5–7.3s show the editor's beliefs loop quiescing), in order:
1. **Trace first** — ms-stamp each pipeline hop (recv→compile, settle→rungo, rungo→run_phase) with the
   existing `H.trace`/Storui copy-trace instruments; read where the seconds actually sit. Don't guess.
2. **Conditional self-pump on the Lies channel/run `req**` pile** — while in-flight conditions hold (pending
   compile / unacked rungo / run awaiting `run_phase`), re-arm a paced ~200ms `setTimeout → i_elvisto(w,
   'think')`, self-terminating at quiescence. The proven `req_compile` trickle shape (`Lang.svelte:~1905`)
   generalised — bounded by the same conditions so it can't spin forever. **In tension with** Editron's
   `Trickle → single wake` TODO (which wants the opposite); decide from the trace — likely pump now, wire the
   event wakes as found.
3. **Track it as durable in-document markers**, not transient state (the doctrine) — `%Map`/region/Mapule or
   marks in the Editron Book — so the swamp is *related to as it mutates*, not re-discovered each session.

Leftover small ones: **normalise the dige** (bomb 3) so the CLI poll agrees again as a 2nd confirm path;
 **`note()` `important` flag** in `Tribunal.g` (frozen spine — recompile+promote) so carrier CLOSE/reconnect
  persist 60s.

## Working tree — all committed
The feedback machine + lag fix landed in `7fdb8126` "fix remote compile lag" and predecessors
 (`Lang.svelte` e_Lang_dock_content force_active branch, `LangCompiling.svelte` `Lang_compile_dock`
  stateOverride + `Lang_compile_source_state`, `scripts/LakeRace.*`, `scripts/ghost_compile.ts`,
   `src/lib/server/relay.ts`, `LiesLies.svelte`, `Tribunal.go` + channel/Brink). The `%Aim`/Brink half
    rides in `spec/Lens_handover.md`. Tree is clean. Bomb #6 ("hard-reload after editing a ghost") is
     corrected — [[hmr-remixes-ghost-methods]]; methods re-mix on HMR.

---

# The swamp underneath — cluster-trust, and the CLI that should be an Idento

Everything above is tactics. This is *why the area stays swampy* and where it should head — the
frame for attacking it fresh rather than chasing one more gap.

**One missing weld:** identity is forked three ways and lives on **messages**, not **connections**.
So who / where / trusted / alive get re-derived, differently, on every frame — and each gap above
(corr-routing, the half-open prune, `undeliverable`, the dead dige-poll, the two-editor fan-out) is
a patch over the *same* joint. When every fix spawns another special case, that's a missing
abstraction, not a pile of bugs.

## How a socket's identity is declared today

| Mechanism | Sets | Authenticated? |
|---|---|---|
| `?addr=<self>` query (`relay.ts:404`) | routing addr in `locals` | **no** — self-declared string |
| `become {role}` (`relay.ts:226`) | editor/runner, set-once | **no** — a bare string |
| `gen_write` `sign` (`relay.ts:282`) | the cluster key, `verifyHeader` | **yes** — and as a side-effect `setRole('editor')` (`:307`) |

And `cluster_trust.ts:52` — `prepubOf(pub) = pub.slice(0,16)` — **already derives a routing address
from the key.** The identity-as-address is sitting right there, fully formed, *unused*: the transport
routes by the self-declared `?addr=` instead. The one place a key meets a connection is a side-effect
buried in `handleGenWrite`.

## The cluster token is a low-functioning peer

The Idento is a real ed25519 identity (address, provable key, trust status) **demoted to a stamp on
individual messages**: it signs a header and nothing else. It does not identify the *connection* (the
CLI has no `?addr=` at all → the entire `corr`/`ackBack` apparatus exists *only* to route a reply back
to an address-less sender), confers **no presence** (→ the half-open zombie), and Peeroleum's own
`%Ud` is force-stamped, so the designed peer-trust layer is vestigial in this path. The tell is the
**inversion: the most-trusted party — it can write code to disk, an RCE — is the *least*-integrated
peer.** No address, no inbox, no liveness, no handshake.

> Same shape one layer up: **ghost_compile is a low-functioning compile-*request*** — it does the
> mechanical write but never completes the *intent* (the stuck `Change/compile pending`, the missing
> run-arm + `✅` that only an in-app **Esc** (`e_Lang_compile` → `Lies_run_arm`) fires). A token that
> can't be a peer; a request that can't finish an intent. One smell, two layers.

## The direction (agreed): the CLI gets an Idento, the relay gets dumber

Collapse the three declarations into **one identity, proven once at connect**:

- **The CLI mints/loads its own Idento and proves it on connect** (sign a relay nonce). The relay
  binds `addr = prepubOf(pub)` ↔ socket ↔ verified pub. The CLI is now a first-class addressable
  peer — **the corr/ackBack hack evaporates; the ack just routes home by `to`-prepub.**
- **Route by prepub.** `header.to`/`from` are prepubs — one address space for everyone, no role-strings.
- **Capability is a property of the proven identity** ("this pub may compile-request / gen_write /
  run"), checked **once** at the relay against a small table — not re-verified at each consumer
  (today: relay `gen_write` gate *and* editor `ghost_compile_recv` *and* the force-stamped `%Ud`).
- **Presence = a signed heartbeat** from the bound identity → half-open dies, because liveness is
  identity-bound, not `readyState`. Bombs 1–2 and the `undeliverable`-vs-timeout ambiguity dissolve.
- **`%Ud` *is* the proven pub** for trusted infra — no force-stamp.

## "Contractually sensible" — the minimal relay

The relay should know exactly four things and nothing more: **(1)** a connection's proven identity
(`addr = prepub`); **(2)** that identity's capabilities (trusted flock + a small table); **(3)**
liveness (keyed heartbeat); **(4)** how to route a frame by its `to`-prepub. **Drop:** `?addr=`
self-declaration, `become` role-strings, the `gen_write`→`setRole` side-effect, `corr`/`ackBack`, and
the `readyState`-trusting `deliverLocal`. Everything the relay currently *fakes* — role, address,
liveness — becomes a consequence of one authenticated fact.

## The honest constraint (don't collapse this away)

Two populations: **trusted cluster infra** (claude / editor / runner — in the flock) and **untrusted
music-app user peers** (NOT in the flock — they genuinely need the hello/trust handshake + earned
`%Ud`, spec §8). The clean frame is **one mechanism (a key), two trust tiers** (in-flock → full
capability; not-in-flock → handshake-earned, limited). Today's design accidentally grew *three*
mechanisms for what should be one with a tier check. A redesign that erases the user-peer handshake is
wrong — that complexity is essential, not accidental. Also note the v1 "trust-everything" is a
deliberate staging choice; the swamp is that it's *half*-migrated (the PKI guards two RCE frames and
nothing else), so you can't reason cleanly because some edges are gated and some aren't.

## For the ten of you

The answer looks like: **the relay gets dumber, the CLI gets realer, and the next gap needs no new
special case.** Rough dependency order; each step is independently shippable and each *removes* code:

1. **CLI Idento + connect-proof + prepub routing** — the keystone. Kills corr/ackBack and the
   address-less return path outright. (`gen-cluster-identos.ts` already mints a `claude` key; the
   missing piece is proving it *on connect* and binding `addr=prepub`, not just signing payloads.)
2. **Identity-bound liveness** (keyed heartbeat at the relay) — retires the half-open saga.
3. **Capability table** at the relay — one verify site; folds `gen_write` (drop the `setRole`
   side-effect) and `ghost_compile` under one check.
4. **Converge the compile paths** — ghost_compile completes the *intent* (settle + arm + verdict)
   the same way Esc does (ties to the wedge/self-heal fixes above).
5. **Normalise the dige** (bomb 3) so content-addressing agrees — orthogonal but cheap.

Litmus test for any proposal: **if it adds a special case, it's the wrong step.** The whole point is
that one weld — *identity on the connection, not the message* — dissolves many gaps at once.
