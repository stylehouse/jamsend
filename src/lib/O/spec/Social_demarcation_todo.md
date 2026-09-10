# Social_demarcation_todo.md — the substrate/app boundary, and the accessor it never had

A **working `_todo`** (not self-promoted — the owner reads + preens). Precipitated by a live walk on
 2026-09-06 in which SoundPooling was dead for two days for a reason that had nothing to do with
  SoundPooling.

## 0. WHAT TO GET ON WITH NEXT (refreshed 2026-09-08 for the morning slog)

### ⚑ NEXT BIG ONE — KILL THE `?addr=runner` SOCKET (owner 2026-09-09: *"remove entirely the second websocket for addr=runner and have some other way to find runners"*)

> **✅ STEP 3c IS ARMED AND LIVE — 2026-09-10, both stages (owner: *"it's weird calling the role an
>  address right? autistic"*).** `ROLE_IS_NOT_AN_ADDRESS = true`. A role channel now dials `/relay`
>   bare; `become` binds the role, the signed `hello` binds the identity.
>
> **Proven, in this order, with the owner watching:**
> 1. **Stage 1 was verified LIVE before arming, not assumed** — `🌉 relay bridge UP` arrived ONCE in the
>     live console instead of three times, which is the `broadcastControl` dedupe from the same save, so
>      `ownsDoor` was demonstrably running. *(The previous attempt armed on the assumption that a
>       restart was still pending. It was not, and that is what split the fleet.)*
> 2. **The dial changed** — `🛰 ws OPEN ws://localhost:9091/relay — flushing 0 buffered`. No `?addr=`.
> 3. **The broadcast path works** — a bare `ping` (`to:'runner'`) answers. *This is the exact path that
>     went silent last time; it is the check that matters, not the directed one.*
> 4. **No Book regression** — `SwarmDoor` measured `ok_pct 1, caveat 0, 5/5` immediately BEFORE arming
>     and identically after.
> 5. **The mixed fleet holds** — four player tabs still on the old build (`?addr=player`) all answer
>     alongside the addr-less runner. This was the failure last time and it is now the proof.
> ⓘ **Bonus, unlooked-for:** the runner now appears in `runner_ask runners` as `✓ live`. It never did
>  before — the census was falling back to `qaddr`; addr-less, it reads `declaredRole` and gets it right.
>
> **Still true and still the next step:** this only stops the role being *spelled* as an address. The
>  second socket itself survives until the one-socket migration below.
>
> **What it does.** `Socket_real`'s `home()` (Ghost/N/Tribunal.g) emits `?addr=` **only for an
>  identity-shaped name**; a role channel (`runner|editor|player`, whose `%Peering` is NAMED after the
>   role) dials **addr-less** and is bound by its `become` a message later. One function, not a campaign —
>    `become` already bound the same name *and* stamped `declaredRole` (added 2026-09-09 for exactly this).
>  It sits behind `let ROLE_IS_NOT_AN_ADDRESS = false` in that function. **Flipping it early splits the
>   fleet.**
>
> **⚠⚠ THE FAULT THAT DISARMED IT — measured, not feared.** The own-door rule consulted **only `qaddr`**.
>  So ONE straggler still dialling `?addr=runner` — an un-reloaded tab, a daemon on old code, a test
>   harness — **claims the door** at `runner`: `own` goes true and every addr-less role channel is dropped
>    from the `to:'runner'` **broadcast**. Nothing errors. Dispatch just stops finding half the flock.
>  I shipped the client half first and it bit within the hour: the runner I reloaded answered a directed
>   `--runner=<prepub>` ping and ran `SwarmCohort` green, then a bare `ping` (which IS a `to:'runner'`
>    broadcast) came back *"no runner connected"*. I had written "provably unmoved in all four cases" in
>     this very banner an hour earlier. The trace was right about each case in isolation and wrong about
>      the **mixed** fleet, which is the only state a rollout is ever actually in.
>
> **The relay-side cure (in the tree, stage 1).** `deliverLocal` now asks `ownsDoor(ws)`: a socket owns
>  `to`'s door if `qaddr === to` **or** `declaredRole === to`. For a role, `become` *is* the front door —
>   so old and new sockets are equal claimants and the bucket fans out to both, which is what a role
>    bucket always meant. Safe with old **and** new clients, which is what makes the order work.
>
> **THE ORDER, not optional:** (1) restart the dev server so `ownsDoor` is live · (2) flip
>  `ROLE_IS_NOT_AN_ADDRESS` to true · (3) recompile Tribunal.g · (4) reload the tabs, stragglers included.
>
> **⚠ AND THE REFACTOR THAT LOOKS RIGHT AND IS NOT.** I also proposed re-keying own-door off the socket's
>  `bound` set — "use the bind it PROVED with a signed hello, not the `?addr=` it merely CLAIMED". That
>   re-breaks the *original* bug: a role channel hellos too (the bind is unconditional), so its `bound`
>    **also holds the prepub** — both sockets qualify and every music chunk is delivered twice again.
>     Written beside `deliverLocal` so it does not get re-proposed.
>
> **Tests, which is what actually caught this.** `relay-test.ts` gained the new road's contracts: an
>  addr-less socket bound by `become` receives `to:'runner'`; a station-less runner is still individuated
>   through it; **it re-binds across a reconnect** (the old dial re-bound in the URL for free, the new one
>    owes it entirely to `Socket_real` re-firing its open_hooks); and the anti-doubling rule still holds
>     with an addr-less role channel. The two broadcast cases failed on first run — that is the whole
>      finding. `relay-test.ts`, `runner-ask-test.ts`, `ceremony-addr-test.ts` all PASS now.
> ⚠ **`scripts/Presence.spec.ts` is a DEAD GATE and has nothing to do with any of this.** It fails at
>  `attachRelay` with `TypeError: WebSocketServer is not a constructor` (relay.ts:119, the `ws` import
>   under the vitest/jsdom environment). Baselined against the COMMITTED `relay.ts`: identical failure, so
>    it is pre-existing and environmental, not a regression. Worth knowing because a harness that cannot
>     run is a gate silently lost — the same shape as everything else in this thread.
>
> **⚑ TWO MORE RELAY BUGS, found in the owner's own console 2026-09-10 and fixed — they ride the SAME
>  dev-server restart as stage 1, so do them together.** Both were live all along; neither is from the
>   `?addr` work. They surfaced when the owner said *"reloaded… everything's running slow as"*.
>
> **1. `broadcastControl` fanned per BINDING, not per socket.** `locals` is addr → Set<socket> and one
>  socket is deliberately bound under several addrs (role · prepub · granted seat), so walking
>   `locals.values()` visited it once per binding. Every control frame arrived **doubled or tripled** —
>    `🌉 relay bridge DOWN` and `UP` logged 3× per event in the live console. It matters because
>     `peer-relay` broadcasts on every failed r2r dial, so a reconnect storm gets multiplied by the
>      bindings each tab holds — frames the tab parses on the belief path, exactly when it is already
>       struggling. And it made the log **lie about how many events happened**, which is how it hid:
>        three DOWN lines read as three drops, not one drop counted thrice. Now deduped by socket.
> ⚠ **The first test I wrote for it PASSED with the bug in place.** It compared a 3-bound socket against
>  BOB — but BOB is multiply bound too (`?addr=BOB` + `become runner`), so per-binding fan-out inflated
>   both sides equally and read 3 vs 3. **A comparison between two affected things measures nothing.**
>    The assertion is now absolute (one drop is ONE event, so the count must be exactly 1) and is
>     verified in BOTH directions: green with the fix, red with the bug reintroduced.
>
> **2. `dialEditor` killed its own in-flight dial — a self-inflicted storm, fired by reloading.**
>  `peerLink` is assigned when the socket is CREATED, well before it opens. A second `dialEditor()`
>   during that connect window saw "not OPEN", concluded it was the stale half-open case, **closed it**
>    and dialled again. And `relay.ts` calls `dialEditor()` on EVERY browser reconnect — so reloading a
>     few tabs made each murder the previous one's dial. The tell is a burst of `🌉 relay bridge DOWN —
>      error=WebSocket was closed before the connection was established` and `close:1006`, which is
>       exactly what was on screen. Fixed by treating `CONNECTING` as alive. The stale-link cure still
>        applies to CLOSING/CLOSED, and a CONNECTING link that never opens is still covered by the
>         existing 5s watchdog (it broadcasts and calls `scheduleRedial`), so no "state stuckness"
>          returns.
>
> **Diagnosed but NOT fixed — needs live eyes.** `⚠ DROPPED bridge→ pong seq=50 → '<prepub>' ×60 — no
>  local socket is bound`, alongside a `→EDITOR (silent 94s)` Brink badge. Editor pongs to the runner's
>   **bare** prepub are dropped while the live body sits at its granted seat (`<prepub>_9514`). I could
>    not pin whether the bare name is unbound or squatted by a dead socket without watching it happen,
>     and guessing at a delivery fix is how this thread lost hours before. ⓘ Related: the `_9514` suffix
>      is a **random per-page body id**, not a duplicate count — `ceremony-addr-test.ts:112` mints rids
>       exactly so (`ridA = '7011'`), and the relay's own collision counter would emit `_1`, not `_9514`.
>
> **Also fixed while in here:** `const TSEP` was a **raw NUL byte** in the source. Git therefore treated
>  the whole of `relay.ts` as BINARY (`git diff` → `Bin 70329 -> …` and nothing else) and plain `grep`
>   skipped it silently. On the file whose review matters most. Now written `'\u0000'` — same separator,
>    same runtime value (the tally contracts still pass), source pure ASCII. ⓘ The diff of THIS change is
>     still binary because the committed side holds the NUL; read it with `git diff --text
>      src/lib/server/relay.ts` (`--stat` still says `Bin`). Every diff after it commits is normal text.
>
> **Deliberately NOT done.** The relay still **accepts** `?addr=<role>`. Removing the *second socket
>  itself* — the actual prize in step 3 — is untouched. **3a (the keepalive) stays deferred**: see the
>   warning below, it fails silently both ways and wants someone watching.
>
> **Next, if picked up:** `?addr=<prepub>` could go too, removing the parameter entirely — but only by
>  giving own-door a new discriminator. The clean one is already on the socket: **a station is one that
>   hello-bound an address having declared NO role** (`declaredRole == null`) — no new state, proof-based,
>    and free of the `bound` trap. Not attempted; it is a delivery-rule change and wants its own live walk.

### ⚑ SOLVED — THE ADDRESS DROP (`DROPPED bridge→ pong → '<prepub>'` / `→EDITOR (silent 94s)`)

**THE LOST IDENTITY BIND. Out is a ROLE, back is an IDENTITY — so only the return leg can drop.**
- The runner pings the **editor role**: `Lies_ping` → `to:'editor'` (`LiesLies.svelte:1671-1685`).
   Role-addressed, so it survives a lost identity bind and the tab looks perfectly alive.
- The editor answers **identity-addressed**: `Lies_pong` (`:1717-1719`) sends `to:<the ping's from>` —
   the runner's **bare prepub**, never its seat.
- A tab re-binds its ROLE synchronously on every reconnect (`become`, in `on_open`). It re-binds its
   IDENTITY only through the signed `hello` — which is **fire-and-forget**: it bails on a missing key
    (`if (!idento?.pub || !idento?.key) return`), swallows everything in a bare `catch {}`, and
     **nothing ever checks that `hello_ok` came back** (`LiesLies.svelte:419-460`, verified).
- Miss one hello and the socket talks OUT flawlessly while every `to:<its prepub>` frame is dropped at
   the relay **for the life of that socket**, with nothing but a terminal warning to say so. The badge
    goes `(silent Ns)` because `sc.last` is written ONLY by `Lies_pong_recv` (`:1763`) — the very pongs
     being dropped are what would refresh it (`Rundar.svelte:126,131,146`).

**The `locals:` listing was never a contradiction.** It is printed at **bind/unbind events only**
 (`relay.ts:952` browser-bound · `:524` become · `:1004` disconnected) — never at a drop. So it is a
  snapshot from a different moment. Hours went into that apparent paradox; the drop line now says which
   kind of nothing it found (see the `bindState` hunk below), which would have ended it in a minute.

**Also settled: `<prepub>_9NNN` is the LiesLies SEAT-DODGE, not a duplicate count.**
 `LiesLies.svelte:455` — `header.from + '_9' + String(100 + Math.floor(Math.random() * 900))`. So the
  live shape `role, <prepub>, <prepub>_9514` is **ONE socket wearing three binds**, not three tabs.

**Reproduced and red/green proven.** `relay-test.ts` carries the repro and **exits 1 on purpose** — one
 known red, everything else green. `RELAY_MOD=./_relay_rehello.ts npx tsx scripts/relay-test.ts` runs
  the same suite against a patched copy and goes fully green. Kept red deliberately: a suite that goes
   green while a known bug is live is the `ok:true`-hides-a-caveat failure this corpus already knows.

**✅ FIXED CLIENT-SIDE AND LIVE 2026-09-10 — `LiesLies.svelte`, no dev-server restart needed.**
 The latch shape below is what shipped. Proven on the live runner: a reload now logs one hello, one
  seat dodge, one `hello_ok`, with the retry dormant; `SwarmDoor` measured `ok_pct 1, caveat 0, 5/5`
   before and after. `relay-test.ts` is **green again** — its check was repointed from the relay-side
    nudge to the relay CONTRACT the cure depends on (*a fresh hello on a NEW socket re-binds the
     identity*), and verified to go red without the retry and green with it.
 ⚠ **The first live run caught a flaw in the fix itself, and only because the retry is NOT silent:**
  `🪪☠ hello send failed (Still in CONNECTING state)`. `Lies_channel_live` — the retry's gate — checks
   only `channel_up && connection` and says **nothing about readyState**, so it reads true during the
    connect window; the retry fired mid-connect, threw, and raced the real on_open hello (two hellos,
     two seat dodges). Cured with an explicit `readyState !== 1 → return` inside the sender, and the
      attempt counter moved behind that gate so a skipped attempt is not counted as a failed try.
      *The lesson is the fix's own argument: a silent retry would have hidden this.*
 ⓘ The relay-side `rehello` nudge below stays **unbuilt** — belt-and-braces, and it costs a restart.
  `scripts/_relay_rehello.ts` (the scratch copy that proved it) has been deleted.

**⚑ THE LATENT TWIN — `Swarm_station_up`'s hello has the same shape, on the socket that carries MUSIC.**
 Found by sweeping for the pattern rather than the symptom, 2026-09-10. `Swarm.g:2271` (soul hello) and
  `:2286` (body hello) both `port.ws?.send(...)` and hope.
 - **Not vulnerable to the readyState flaw** — both sit inside an `on_open` hook, so the socket is OPEN.
 - **But it has no acknowledgement check.** Swarm *does* set `on_hello` (`Swarm.g:2196-2197`) and uses
    it to adopt the granted address and rehome — so it hears a `hello_ok` that arrives. **Nothing
     detects one that never arrives, and there is no retry.** Same send-and-hope as `w:Lies` had.
 - **Why it would be worse there:** this is the identity world's station socket, so a lost bind drops
    `to:<prepub>` traffic — swarm frames and **music chunks** — not just editor pongs. It would read as
     "the transfer stalled", not as a stale badge.
 ⚠ **MEASURED shape, INFERRED consequence.** I verified the code path; I have NOT seen this fail live,
  unlike the Lies one. Do not write it up as a known outage cause.
 **Deliberately not fixed here:** it wants a `.g` recompile plus a tab reload on the music path, with
  someone watching. The cure is the proven one — the same latch, cleared on open, stamped by
   `on_hello`, retried on a tick — and `Swarm.g` already has the `on_hello` hook to hang it on.

**The two fix options as they were assessed:**
- **(preferred, no restart — THIS IS THE ONE THAT SHIPPED) Make the hello non-silent, client-side.** Retry it from the existing
   keepalive tick until it is acknowledged — closes the hole at its source, touches only `LiesLies`,
    and needs no dev-server restart (so it costs the flock nothing).
  **The exact shape, which needs no socket-open timestamp** — a latch cleared on open, stamped on ack,
   retried while unset. Idempotent by construction: it stops the moment `hello_ok` lands, and a tab
    with no key never starts.
  1. **Stamp the ack.** `w:Lies` does not currently listen for it, but `Tribunal.g:318-322` already
      hands `hello_ok` to `w.c.on_hello(frame)`. So set, once, beside the channel standup:
      `w.c.on_hello = () => { w.c.hello_ok_at = Date.now() }`
      ⓘ Safe from collision: `on_hello` is the identity world's key (Swarm adopts the granted addr
       through it); this is `w:Lies`, a different world. The 2026-09-10 key scan found the two worlds
        share **no** `.c` name.
  2. **Clear the latch on every (re)open**, at the top of the existing `port.on_open(async () => …)`
      hello block (`LiesLies.svelte:419`): `delete w.c.hello_ok_at`
  3. **Retry in the keepalive tick**, beside the existing 6s `last_ping` throttle
      (`LiesLies.svelte:1664`): if `H.Lies_channel_live(w)` and `!w.c.hello_ok_at` and a key exists,
       re-send the same signed hello. Re-sign each attempt — `handleHello` checks **ts-freshness**, so
        a replayed stale header is refused.
  ⚠ **Mint a FRESH seat-dodge `want` on each retry** (`LiesLies.svelte:455`), or a retry can collide
   with the seat the earlier attempt actually won and get suffixed again for no reason.
  ⚠ **Do not swallow the retry's errors too.** The bug is not the missing hello, it is that nothing
   noticed — `catch {}` is what turned a one-RTT hiccup into a dead socket for the life of the tab. Log
    the retry, and log when the latch has been unset for more than a few ticks.
- **(relay-side) A `rehello` nudge.** On dropping an identity-shaped addr, `broadcastControl({control:
   'rehello', addr})`, rate-limited per addr; the tab re-sends its signed hello and the bind is back
    within one RTT. Belt-and-braces, but it is a wire-protocol addition AND a `relay.ts` save, i.e. a
     dev-server restart. Do it second, if at all.
- **Take the `bindState` logging hunk either way** — it distinguishes "addr not in locals at all" from
   "addr IS in locals, sockets all dead", and names any family seats still bound.
⚠ Both relay hunks ride a dev-server restart (`vite.config.ts:3` imports `relay.ts`). Land when idle.

**⚑ SIDE-FINDING, measured, real today and unrelated to the drop:** an **unauthenticated
 `?addr=<prepub>` socket CAPTURES a hello-verified identity's door.** `ownsDoor` reads the *claimed*
  `qaddr`, not the *proven* `bound` set (`relay.ts:275-276`) — measured: the real hello-bound tab got
   nothing, the squatter got everything, **zero drops and no log line at all**. A silent black hole that
    produces the same `(silent Ns)` badge with nothing in the terminal. `ceremony-addr-test.ts §B`
     already names the disease.
 ⓘ The owner's one-socket ruling **dissolves this** — it deletes the own-door rule outright. Until then
  it stands, and note the trap: keying `own` on `bound` instead does NOT fix it, it re-breaks the
   doubling (a role channel hellos too, so its `bound` also holds the prepub). Neither field alone is
    right, which is itself an argument that the rule should go rather than be tuned.

**The case is already written, in five places in the code, by five different people fixing five symptoms
 of one cause.** Nobody has to be persuaded; the arguments just need collecting:

- `relay.ts` (the hello bind): *"`bind` is additive and `deliverLocal` fans to the whole Set, so every
   `to:<prepub>` frame — swarm frames, MUSIC CHUNKS, wormhole replies — was delivered TWICE… the inbox
    climbs to the 2000 cap and every per-frame query is O(depth), so the tab gets slower as it fills — a
     runaway that reads as 'the app is broken'."* The cure was an **own-door rule at delivery**: prefer a
      tab's station socket. A workaround for a tab having two sockets.
- `Auto.svelte`: a **daemon** must take `creduler:1` WITHOUT `runner:1`, because *"a second claimant of
   `runner` silently receives every frame meant for a human's tab"*.
- `Auto.svelte` again: a **humdinger music page** must not claim the seat either — the owner's incognito
   console *"drowning in 'pier editor holds 2050 unemits'"*, because every Big\*land tab was binding
    `/relay?addr=runner` on the shared relay and drinking the editor's dispatch flood.
- `runner_ask.mjs:685`: *"`to:'runner'` for everything, and the relay FANS a role frame to every runner
   tab — so with two tabs up…"*, which is why `--runner=` pinning had to be invented.
- The **census itself** is the workaround wearing a hat: it broadcasts to a role, the relay spends the
   asker's `corr` on the FIRST ack, so enumerating the flock needs repeated stochastic rounds with a
    minimum-round floor *"because an early-stopping census under-reports"*.

**One shared well-known name, many claimants, and a growing list of who is forbidden to claim it.** Every
 fix so far has been another exclusion. That list is the smell.

**THE REPLACEMENT IS ALREADY HALF-BUILT.** `Cluster_spec §3.2b` layer 4 says it: *advertise → the
 `%Runner` roster; engage `to:<prepub>`*. Engagement is ALREADY per-prepub. Only DISCOVERY leans on the
  role name — and the relay does not need to be asked stochastically, because **it already knows**:
   `locals: Map<addr → Set<WebSocket>>`, plus a per-socket `bound` Set and its `qaddr`. It can simply say.

**The plan, additive first — land the new road, prove it, THEN delete the old one:**
1. **`control:'census'` on the relay** — answer the bound addresses with their roles. Deterministic, one
    round trip, replaces the stochastic sweep. Purely additive: no existing frame path changes.
2. **`runner_ask` resolves a prepub FIRST**, then addresses `to:<prepub>` for every op. `--runner=` stops
    being a workaround and becomes merely an override.
3. **Then remove** the `runner:1` role claim, the `?addr=runner` dial, and — the actual prize — the
    exclusion list and the own-door delivery rule that exist ONLY to police a shared name.
4. Re-run the ceremony + pool Books, and walk one live dispatch, before deleting anything in step 3.
**Do NOT do 3 before 1 and 2 are proven live.** A tab that cannot be found is a tab that cannot be fixed.

**✅ 1, 2 and 4 LANDED AND PROVEN LIVE 2026-09-09** — `control:'census'` on the relay; `declaredRole`
 kept per socket at `become` (the third thing a become means, which nothing recorded); `runner_ask`
  courting by census and addressing by prepub; a re-court when a courted tab accepts a run and starts
   nothing (`uid:null` — measured live the day the Story ghosts were renamed under a running tab).
  Proof: two real Books to `done` unpinned (MusuPoolBytes 5/5, MusuPoolFill 6/6, both caveat 0), no
   double dispatch, and the census caught a live fault on its first look — **eed, an end-user music
    page, holding 3 sockets with one declaring `runner`**, i.e. sitting in the shared dispatch seat that
     `Auto.svelte`'s humdinger exclusion exists to prevent.

⚠ **STEP 3 IS NOT A DELETION, AND THE PLAN ABOVE WAS WRONG ABOUT THAT.** The role name has a SECOND,
 legitimate user that has nothing to do with discovery — the editor uses `to:'runner'` to mean
  **"any runner of that kind"**, deliberately, in two places:
- `LiesLies:1706` — the keepalive ping: *"a role-broadcast ping (`to:"runner"`, **correct** — the editor
   wants ANY of that kind)"*. It is a CARRIER fact ("our send leg works"), not a request to a specific tab.
- `LiesLies:2127` — `Lies_dispatch_target`: `if (!cands.length) return {}` — an empty roster falls back
   to broadcast, to catch a runner that is up but has not advertised yet.
**So the question step 3 actually asks is: what should "any runner" mean once no shared address exists?**
 Both answers are the same move already made in the CLI — *stop shouting at the role, ask the relay*:
 (a) the keepalive wants a live carrier, so it can ride the census or ping one rostered prepub;
 (b) the dispatch fallback wants discovery, which is exactly what the census is for — and an empty census
     is an honest "no runner", where a shout was only ever a guess with a timeout.
**Ordering, CORRECTED AGAIN — and smaller than either earlier version.** *"Give the editor a census"* was
 wrong: **the editor already has one.** A runner fires an immediate advertise the moment its socket opens,
  first connect and every reconnect (`LiesLies:469`, deliberately not via the keepalive), so the `%Runner`
   roster is populated within ONE RTT. The broadcast fallback therefore covers a sub-RTT window and
    nothing else, and a second census cache beside the roster would be two sources for one fact.
 So the real work is only this:
 - **3a — the keepalive.** The editor pings `to:'runner'` every ~5s to learn "is anything of that kind
    alive". Replace with a ping to each ROSTERED prepub: strictly more informative (per-runner liveness
     instead of one aggregate), and the attribution machinery already exists — a pong carries `from`
      precisely because one broadcast used to come home as N indistinguishable pongs (2026-08-04 socklog).
       With 1–3 runners the cost is 1–3 frames per 5s instead of 1.
 - **3b — the dispatch fallback.** `if (!cands.length) return {}` becomes an honest "no runner yet".
    It is covering the window between a socket opening and its first advertise landing — under an RTT.
 - **3c — stop binding `runner`.** Only then, and it is now genuinely a deletion.
 ⚠ **3a is a HEARTBEAT change — do it with someone watching.** `Lies_ping` rides
  `Peeroleum_send_consumer`, which sends to the transport world's single Pier, so per-runner pinging
   means the editor addressing N rostered prepubs instead of its one pier. The failure mode is silent in
    both directions: the editor stops seeing live runners, or keeps believing dead ones are alive. That
     is the wrong thing to land unattended — everything else in step 3 is loud when it breaks.
 - **3d — the own-door delivery rule and the two exclusions fall out**, having nothing left to police.
 ✅ **RULED 2026-09-10 BY THE OWNER — THE COLLISION IS SETTLED. The role socket is an ACCIDENT, and the
  target is ONE SOCKET PER TAB.** Asked directly ("legitimate second door for control-plane traffic, or
   an accident we're removing?"), the answer was *collapse to one socket*, consistent with the original
    words that opened this section — *"remove entirely the second websocket for addr=runner"*.
  **What the ruling DELETES:** `relay.ts:190`'s promised second control-plane map (never build it —
   retire the promise, and `SoundPooling_todo:118` with it) · the whole **own-door rule** in
    `deliverLocal`, which exists only to arbitrate between a tab's two sockets · **`?addr=` entirely**,
     both halves, not just the role half · the `to:'runner'` broadcast bucket.
  **What it REQUIRES, and this is the real work:** a tab keeps ONE socket, bound at its prepub by signed
   hello. `become` survives but only to stamp `declaredRole` — it stops binding a name. Finding runners
    becomes a **census over `declaredRole`**, not a frame to a shared address. And `runner_ask`'s op
     handler must MOVE to wherever a `to:<prepub>` frame now lands, which is the part that broke it in
      August (*"the whole flock read as down for hours"*) and the part to design most carefully.
  ⚠ **A consequence worth seeing early:** with no `to:'runner'` bucket, the CLI can only find runners via
   the relay `census` op — and that op is currently GATED to hello-bound askers, which the CLI is not.
    The gate was right when census was a convenience beside a working broadcast. Under this ruling it
     becomes the ONLY road, so the gate needs re-deciding BEFORE the bucket is removed, or the CLI goes
      blind.
  **Two options fall away on inspection, which leaves one.** A *roles-only listing naming no identities*
   is useless: the identity IS the address the CLI must then dial, so a census without names answers
    nothing. A *relay-issued token* is real work and needs somewhere to keep the secret.
  **The remaining option is that the CLI mints an ephemeral keypair and hellos like anyone else** — it
   already links `@noble/ed25519` (`relay-test.ts` signs helloes with it), so this is a few lines and
    needs no change to the gate at all.
  ⚠ **But be honest about what the gate is worth, because this makes it plain.** `hello` proves
   *possession of a key*, not *authorisation* — and nothing stops any caller minting a fresh key a
    moment before asking. So the gate is a hurdle, not an access control, and a self-minted ephemeral
     key satisfies it exactly as a real identity does. That is *already true today* for every tab; the
      CLI adopting it changes nothing about the security posture. It does mean: **do not let this gate
       be the reason we believe presence is protected.** If presence should genuinely be restricted, that
        wants a real decision about who may ask, not a signature check that everyone passes.
  **Ordering note:** `ROLE_IS_NOT_AN_ADDRESS` (the addr-less role channel, staged in Tribunal.g) is a
   waypoint on this road, not a detour — it stops the role being spelled as an address, and the socket
    it addresses then disappears entirely. Owner's call 2026-09-10: **do not flip it unattended**; it
     wants someone watching a live reload.

 ### The one-socket migration — where the real difficulty is (drafted 2026-09-10, after the ruling)

 **The crux is not the socket. It is that HANDLERS ARE REGISTERED PER WORLD.** `Peeroleum.g:200` is
  `w.c.on[type] = fn`, and `Peeroleum_deliver` dispatches on `w.c.on[h.type]` where `w` is the world
   owning the %Peering that received the frame. Two worlds register two disjoint sets today:
 - **`w:Lies`** (16 registrations, `LiesLies.svelte:488-536`): `rungo · become_book · ghost_ledger ·
    runner_ask · grant_offer · wormhole_reply · wormhole_beg · wormhole_req · run_result · run_phase ·
     ghost_compile · advertise · ping · pong`
 - **the identity world** (`Swarm.g:1804`): `pier_hello · pier_accept · pier_confirm · pier_reject ·
    reinvite{,_honour,_seal,_ok} · ive_got · pulse · swarm_hi · suggest{,_got} · repli_ready · charter ·
     roster · crew · ferry{,_want,_cancel,_got,_held} · reach{,_done}`

 **One socket means one world, so the other world's handlers never fire.** An unhandled type falls
  through `w.c.on[h.type]` as `undefined` and is dropped **in silence** — which is exactly the August
   2026 outage the relay still carries a note about (*"every addressed ask — ping, state, steps, snap,
    supervisor, run — went silent … the whole flock read as down for hours"*). Any plan that does not
     answer this reproduces that failure.

 **✅ MEASURED, and it is the good news: THE TWO TYPE SETS DO NOT OVERLAP.** Not one name is in both.
  So a merge cannot silently shadow a handler, which is what would have made this dangerous.

 **Option A — merge the registration onto the surviving world.** The one socket's %Peering lives in the
  identity world; `LiesLies` registers its 16 handlers there too. `w.c.on` then holds both sets, and
   nothing collides. Simplest, no new dispatch machinery.
  ✅ **MEASURED 2026-09-10, then RE-MEASURED wider — and the second pass found the thing the first
   missed.** Pass 1 matched only `w.` / `cw.` and reported **zero** shared keys. But the world is bound
    under other names — `self_w` in Swarm, `lw` in Sounditron — and pass 2, including those, gives
     **57 Lies keys · 82 identity keys · exactly ONE shared: `on_hello`.**
  ⚠⚠ **`on_hello` IS A LIVE TRAP FOR OPTION A, and `Swarm.g` sets it defensively in a way that makes the
   failure SILENT.** Both worlds want that hook for different jobs — Lies stamps the
    hello-acknowledged latch (added 2026-09-10 with the lost-identity-bind fix; **before that fix the
     sets really were disjoint, so this collision is newly created**), while Swarm adopts the relay's
      granted address and rehomes. And `Swarm.g:2196` guards with **`if (self_w.c && !self_w.c.on_hello)`**
       — it only installs its hook when the slot is empty. So on a merged world, whichever ghost stands
        up FIRST wins, and if that is Lies, **Swarm silently never installs its adopt-and-rehome logic
         at all.** No error, no log, just an address that stops being adopted.
  **⇒ Option A must make `on_hello` a fan-out, not an assignment** — a list of hooks the carrier calls
   in turn, exactly as `w.c.on[type]` is a registry rather than a single slot. That is a small change to
    `Socket_real`'s control branch (`Tribunal.g:320`) and it should land BEFORE any merge, not with it.
  ⓘ Scan is `scratchpad/ckeys.mjs`, seconds to re-run. It still cannot see a key written through a
   helper — `on` is the known case (Lies registers via Peeroleum's helper, so it shows only in the Swarm
    set) and is the deliberate merge point rather than a collision.

 **Option B — a type router in `Peeroleum_deliver`.** Keep the worlds separate; when `w.c.on[h.type]`
  misses, consult a registry of sibling worlds that claim that type. More machinery, but it keeps the
   ghosts' state apart and makes "who handles what" explicit and inspectable instead of implicit in
    whichever world happens to own the socket.
  ⚠ It must **fault loudly on an unclaimed type**, never fall through silently. The silent fall-through
   IS the August bug; a router that reproduces it has bought nothing.

 **Suggested order** (each step separately provable, which is the whole lesson of this thread):
  1. Enumerate the `.c` key sets; pick A or B on that evidence.
  2. Land the handler reachability change FIRST, while both sockets still exist — so it can be proven
     with everything else unchanged, and reverted alone.
  3. Only then remove the second socket, `?addr=`, the own-door rule, and the `to:'runner'` bucket.
  4. The census gate (above) must be re-decided before step 3, or the CLI goes blind.

 ⚠ *(superseded, kept for the reasoning)* **3d COLLIDES WITH AN OLDER, UNBUILT REPAIR — settle which one wins before touching either**
  (found 2026-09-10 by the stale-claim audit; neither plan knew about the other).
  `relay.ts:190` promises a repair that has never been built, and `SoundPooling_todo:118` records why it
   was wanted: the own-door rule hands every `to:<prepub>` frame to the tab's STATION socket, while the
    `runner_ask` handler lives on the ROLE socket — so an addressed ask never reached a music page and
     *"the whole flock read as down for hours while every tab was alive and healthy"*. The CLI works
      around it today by asking the `player` SLOT with `ask.pub`.
  **The promised repair keeps role sockets and makes delivery smarter:** *"the distinction the first cut
   was missing is not WHICH SOCKET but WHICH FRAME. A role socket has no business receiving a music chunk
    and every business receiving a question about the tab. So it joins a SECOND map … consulted only for
     the control-plane types."* Data frames unchanged, one delivery, on the station socket.
  **3d does the opposite** — it removes a role socket so the own-door rule has nothing to arbitrate.
  They are not both right. The question to settle first: **is a role socket a legitimate second door for
   control-plane traffic, or an accident we are removing?** If the former, build the second map and 3d
    shrinks to "stop binding `runner`" only. If the latter, the repair should never be built and
     `SoundPooling_todo:118` wants retiring. `player` sockets survive either way, so the CLI's
      slot+`ask.pub` workaround is not urgent — which is exactly why this can wait for a real answer.
  **⚑ A THIRD OPTION, cheaper than either, opened up on 2026-09-10 and did not exist when the above was
   written.** The socket now carries `declaredRole` (stamped at `become`). That is the whole content of
    the promised "second map" — *which sockets are role channels* — already recorded, per-socket, with no
     second map to keep in step with `locals`. So the repair could be a **delivery-rule clause instead of
      a data structure**: for a control-plane frame TYPE addressed to a prepub, prefer the bound socket
       whose `declaredRole` is set over the station. Same outcome the note asks for — *"not WHICH SOCKET
        but WHICH FRAME"* — with no new state and nothing to unbind on close.
  ⚠ **Two things to check before believing that, because I got this wrong once already today.** (1) It
   still needs the owner's ruling above: it is an implementation of "keep role sockets", so it LOSES if
    the answer is "an accident we are removing". (2) `ownsDoor` (the 2026-09-10 own-door fix) does **NOT**
     already do this — I assumed it might and it does not. For `to:<prepub>` a role channel's
      `declaredRole` is `runner`, not the prepub, so it does not own that door and still receives nothing.
       `ownsDoor` only made role BUCKETS (`to:'runner'`) safe for a mixed fleet. The prepub-addressed
        control-plane hole is untouched and still open.
  Verified 2026-09-10 that the second map is genuinely absent: `relay.ts` holds five Maps
   (`tally`, `locals`, `ackBack`, `claims`, `dropCounts`) and none of them is it.
 `to:'editor'` STAYS: one editor per relay is a genuine singleton service address, and the runner→editor
  direction (advertise, results) legitimately wants "the editor, whoever that is". `runner` never was.

⚠ **A pattern in my own planning, worth naming:** twice tonight I proposed building something the codebase
 already had — a Story search box (`Storui` has none, but the roster/seek question was already answered
  elsewhere) and an editor census (the roster IS one, refreshed within an RTT). Both times the correction
   came from reading the code rather than the plan. **Read for what exists before writing what to add**;
    this repo is old enough that the second implementation of anything is usually the mistake.

✅ **`control:'census'` IS NOW GATED, as `who` is — a gap I opened, then closed the same night.**
 First cut shipped it ungated on the argument that it was "no worse than the debug surface §3.4.3 already
  records". **That argument was wrong, and the way it was wrong is the lesson:** every op in §3.4.3 has to
   reach a TAB, which can refuse, arm itself, or simply not be there. The census is answered by the RELAY,
    to any socket that connects, with no tab in the path at all. Different door, not the same one.
 **And it is not only the dev server.** `docker-compose.prod.yml:33` runs `npx vite`, so `relayPlugin()`
  attaches in PRODUCTION — an ungated enumerator there is reachable by anyone who can open a WebSocket to
   the public box, handing out the bound identity list, which is PRESENCE. That is precisely what `who`
    refuses to unverified askers, and `who` gives strictly less (it only confirms names you already held).
 **Now:** an asker with no verified hello bind gets `census_error` and zero rows. Proven on the real relay
  code in a standalone harness — `unverified asker → census_error, rows leaked: 0`.
 **Accepted cost, deliberately:** `runner_ask` signs no hello, so it cannot pass the gate and falls back to
  the broadcast court it used before tonight. The CLI loses deterministic discovery — a convenience — until
   asks are signed (§3.4.3); it does not lose the ability to work. Presence stays unreadable by strangers,
    which is a property. **Signing the ask is what earns the deterministic road back**, and it now has a
     second reason to happen beyond the one §3.4.3 gives.
 **THE COST ARRIVED WITHIN MINUTES, AND IT NAMES THE WHOLE PROBLEM.** With the gate live the CLI fell
  back to the broadcast court and started failing **2 invocations in 3** — reporting *"no reply in 12s
   (runner not connected?)"* while two healthy runners sat there answering direct asks every time.
  **Mechanism.** Several sockets bind the shared `runner` seat. A broadcast fans to all of them; the relay
   spends the asker's corr on whichever answers FIRST; a humdinger answers `role:'runner'` too (the
    self-report `isRunner` already calls useless); the CLI courts it, addresses it by prepub, and the ask
     times out. The humdinger veto cannot save it — the veto is skipped for read-only ops, most of them.
  ⚠ **I first told the owner this was "a music page holding the runner seat". That was an INFERENCE and it
   was wrong.** The census aggregates roles per ADDRESS, and several sockets share one address — including
    sockets belonging to DIFFERENT TABS on the same identity (the `<prepub>_NNNN` suffixed seats are family
     seats from the hello arbiter). `roles:player,runner` on one identity row is equally consistent with a
      music page and a runner tab both helloing as that identity, which is legitimate.
  **The candidate filter (`!roles.includes('player')`) is still RIGHT, for a better reason.** An address
   carrying a player's station socket is not reliably dispatchable whoever owns the other sockets, because
    `deliverLocal` **prefers an address's own station socket** when one is bound — so a `to:<prepub>` ask
     lands on the music page, and a runner tab sharing that identity is reachable only at its suffixed
      seat. The address itself is ambiguous. That is a third argument for this whole cleanup, and it is
       about identity-sharing plus the own-door rule, not about one tab misbehaving.
  **Fixed by re-courting on a silent target** (`runner_ask`): drop a tab that acked and then answered
   nothing, and try the next. Measured after: **6/6 pass, the re-court firing twice** — so it is the
    mechanism working, not luck.
  ⚠ **And the first version of that fix never fired once in 8 runs**, because I drew alternates from the
   court's own acks — and a broadcast court comes home with exactly ONE ack however many tabs answered.
    That one-ack rule is written down three times in `runner_ask.mjs` and I coded past all three. The
     alternates have to come from the stochastic sweep, which is the only road that can enumerate.
     **The same mistake shape as the plan corrections above: reasoning where I should have been reading.**
 ~~NOT GATED — a gap I opened without noticing~~ (the original note, superseded above):
 `who`, ten lines below it in `relay.ts`, refuses an asker with no verified hello bind (*"presence answers
  only to verified identities"*). `census` reveals strictly MORE — the whole bound list including identity
   prepubs, versus a yes/no about names the asker already held — and refuses nobody.
 **Why it is still open:** `runner_ask` connects with a bare `?addr=` and never signs a hello, so gating
  census now would remove the CLI's only deterministic discovery before its replacement exists. That
   replacement is already filed at §3.4.3 — sign the ask with the cluster key, verify tab-side, as
    `ghost_compile` already does — and closes this in the same stroke.
 **It is the same exposure §3.4.3 already records for the whole debug surface** (`crew` returns prepubs,
  grants and rebuffs to any caller), not a new class. It now logs when asked, so it is visible while it
   stands. **The moment asks are signed, gate it on the hello bind exactly as `who` is.** Do not let it
    become furniture: an ungated enumerator on a relay that prod also runs is the kind of thing that gets
     rediscovered later by someone who assumes it was considered.

### ⚑⚑ 2026-09-10 midday — THE r2r BRIDGE HIJACK, fixed. Belongs in `Cluster_spec §3.3`'s ladder when the human next preens it.

**Symptom:** the editor dispatches a Book, logs `📤 become_book → runner <prepub>`, and the Brink sits on
 `☎ calling` for ever. The runner shows `→EDITOR (dialing)` and receives nothing. Restarting staging does
  not help. Nothing anywhere names a cause.

**Cause:** `relay.ts` holds exactly ONE `peerLink`, and the passive end sets it from whichever r2r socket
 dialled in LAST. This box runs **three** relays — dev `:9091` (runners), staging `:9092` (the editor),
  prod `:19091`. Prod had no `EDITOR_RELAY`, so it fell back to the hardcoded
   `DEFAULT_EDITOR_RELAY = ws://172.17.0.1:9092/relay?r2r=1`, dialled staging, and **took the bridge**.
    Every `become_book` was then forwarded to prod, which has no runners, and dropped there.

**Fixed:** `EDITOR_RELAY=off` in `docker-compose.prod.yml` (prod has no editor and must never bridge), and
 `relay.ts` now logs `⚠ peer relay REPLACED` when a second peer takes the bridge — the tell that was
  missing. Verified: a `become_book` injected at `:9092` crossed and ran MusuBerth 7/7 caveat 0.

⚠ **The comment in `relay.ts` predicted the risk and got one assumption wrong** — *"prod runs alone …
 nothing on its box's :9092"*. On a box that DOES run staging the dial SUCCEEDS, and connecting to the
  wrong peer is far worse than the `ECONNREFUSED` it was written for, because it looks like it works.

**The diagnosis worth reusing — prove each hop, do not theorise.** I called this "the bridge is down"
 twice from partial evidence and was wrong both times. What settled it: send `become_book` LOCALLY on the
  runner's own relay. Three Books ran green — including one with the editor's exact `ledger_dige`+`pins`
   and one with a deliberately low `seq` — clearing the handler, the version gate, the duplicate guard and
    the reconnect-seq window in a single stroke, and leaving the bridge hop as the only suspect.
 ⚑ Restarting **staging** can never fix a bridge fault: it is the passive end and cannot dial
  (`scheduleRedial` returns unless `role === 'runner'`). **Restart DEV** to re-win the link.

### ⚑ MORNING OF 2026-09-10 — what landed overnight, and what is owed

**The `wormhole/` diff is ALL NOISE this time — measured, not assumed.** 28 files changed by ~40 Book
 runs, and **not one carries a `step=` or `dige:` change**: the 10 `toc.snap` diffs are `TimeTotal`
  timing samples, the 18 `Credulate`/`Credulation` diffs are wall-clock `at=` stamps plus `uses:<ghost>`
   dige lines (which did move — they record the `*ation.g`→`*Testing.g` rename and the `Repli.g` edit —
    but those are provenance, not fixtures). Exactly what a night where every Book matched baseline
     should produce. So `git checkout -- wormhole/` before committing loses nothing and turns a 28-file
      noisy diff into a clean one. Verified with:
      `for f in $(git status --short wormhole/ | awk '{print $2}' | grep -vE Credul); do git diff "$f" | grep -cE '^[+-].*(step=|dige:)'; done`

**Nothing here is committed.** Working tree: `Ghost/N/Repli.g`, `Ghost/M/Heist.g` + their gen ·
 `src/lib/server/relay.ts` · `scripts/runner_ask.mjs` · `scripts/ghost_compile.ts` · and doc edits to
  this file, `Radio_todo`, `Loose_ends_todo`, `GhostHMR_todo`, `Composition_todo`, `Portability_todo`,
   `UI_seams_todo`. All Book-gated where a Book can reach them; all parse-gated.

**Built and gated overnight**
- ⚠ **`repli_dead` NEEDS BOTH ENDS RESTARTED BEFORE IT DOES ANYTHING — do not read a surviving loop as
   the fix failing.** The disclaim is **source-side** (the holder decides its producer is dead and says
    so), and the daemon is the source in the eed↔S pair. At 05:49 the daemon had been up 603 minutes —
     since ~19:46 — while the fix landed at 00:55, so **jamserve is running code from five hours before
      it**. `docker compose up -d --build jamserve` puts the disclaim on the source; the sink half
       (`ra_dead`, the skipped census) needs eed reloaded, which only the owner can do — a music page
        refuses a remote reload by design. Same shape as the `%Card` wire bomb: a change that must land
         on both ends before either end behaves differently.
- **`repli_dead`** (`Radio_todo §0`, open since 2026-08-24) — a resolvable-but-unmakeable id now gets a
   distinguished disclaim (`dead:1`) instead of "re-census me", because the record's producer being dead
    was a fact Ra had been stamping (`rec.c.pcm_dead`) that the wire lane never read. 7 Books, caveat 0.
- **GhostHMR fix B** — `ghost_compile` no longer settles a ticket on the editor's ack. Only the served
   dige-flip can say `compiled`; an acked ticket that never flipped is now **`acked-no-write`**, a named
    fault instead of a false green. Smoke-tested live.
- **The relay census + role-keeping** (see the §0 block above) — deterministic runner discovery, gated
   to hello-verified askers, with `declaredRole` kept as a fact so the `runner` ADDRESS can later go.

**Measured, not built**
- **Cluster toc canonicity** (`Composition_todo`) — carried "UNRUN" for a month. Run now, off git
   history: the runner half of the fix holds; **the editor half does not**. Rows vanish and RETURN, which
    only an overwrite can do, and the writer names itself `role:editor`. Two editors, no canonicity.
- **A stale-claim audit** (`Loose_ends_todo`, top) — five "no live caller" claims checked, **five stale**.
   Nineteen docs carry such claims. Treat any of them as a hypothesis until grepped.

**OWED TO THE HUMAN — decisions, not code. Do these first; the rest waits on them.**

Each of these needs a person, because each is a decision about what is TRUE rather than about what
 compiles. (Plenty of buildable work remains — the ranked list in `Loose_ends_todo`, minus whatever the
  stale-claim audit retires — but none of it is blocked on these, and none of these can start without you.)

1. **Re-swear SwarmReboot `005.snap`.** `since` now survives a reload (item 2), so step 5 fails against a
    fixture that records the BUG as truth (`since:1751700030`, the re-stamp). The live runner shows
     `since:1751700000` held across the reload — the correct value. Only a human accepts a fixture.
2. **Rule on SwarmSpread's five orphaned oaths** (`Crew_todo §0`, corrected there). The Book is genuinely
    red and has been since `4f3ce9cb` retired the adopt road: four of its five declared `%Assertion`
     sentences no longer exist anywhere in `Ghost/`. Striking a declared oath is deciding a promise no
      longer applies, so it is not a session's call. Toc surgery; verify `grep -c step=N` is 1 per step.
3. **Decide whether the `%Card` migration's tolerant reader lands** (item 3). Ruled and unblocked by the
    metaphysics branch, planned, and deliberately NOT started: a describe's mint also crosses the WIRE, so
     it needs a reader that accepts either mainkey on BOTH ends before the mint can flip. Landing the mint
      alone takes the pool dark until someone reloads eed by hand.

**Landed and gated this night, all uncommitted — items 1, 2, 5 and `SoundPooling_todo:640`:** the Pier
 sweep (seven sites, not the ~120 the doc claimed), `since` through the pier stash (plus a Door-freshness
  bug nobody had noticed), the reach `by` binding (a reach's claimed booker is now checked against the
   frame's actual sender), and the live-preferring body pick (the 36-hour outage's own line, which now
    speaks when it falls back to a Cave nobody has heard from). Books: SwarmBody 23/23, MusuPoolFill 6/6,
     MusuPoolRandom 5/5, MusuPoolBytes 5/5, MusuPoolRadio 6/6, MusuReplica 14/14, SwarmHelm, SwarmStaple,
      InvWalk, InvFerry — all caveat 0. Unit: MembershipDoor 7/7, PoolKeep 6/6, ReachTerminal 5/5,
       TwoFounder 1/1, SendTo 1/1.

**The shape those four share, worth noticing before designing the next thing.** None was a broken
 mechanism. In every case the FACT was already present and simply unread — a retired grant nobody asked
  about, a `since` re-invented on each boot, a sender the gate never compared, a `heard` stamp sitting on
   the roster. The substrate had the truth the whole time and no surface to state it through, which is
    exactly this doc's thesis (§0 arc). **Look for the unread fact before adding a new one.**

**Files touched:** `Ghost/S/Swarm.g`, `Ghost/M/Radio.g`, `Ghost/M/Ra.g`, `Ghost/N/Presence.g`,
 `src/lib/O/LiesFunk.svelte` + their gen. Docs: this file, `Crew_todo.md` (a false green corrected),
  `SoundPooling_todo.md` (:640 closed), and the new `Grantwalk_handover.md` for the Grant-mobility fork.

**⚠ THE METHOD LESSON, because it cost hours and will again.** Twice this night a change looked like it
 caused a regression, and twice the truth was that **no recent baseline existed**. MusuHeist's caveat count
  was called "a fixed 4, every run" on the strength of ONE sample, and its real behaviour is a
   documented-since-2026-09-07 broad drift that varies 1→21 run to run. SwarmSpread's "green" was five days
    and many commits old. **Before attributing anything to a change: measure the same Book on the committed
     build.** A bisect took ten minutes and settled both. `git stash` is unsafe here — another branch works
      in this tree — so save the compiled `.go` aside, `git checkout HEAD --` the gen, reload, measure,
       restore. Reload the runner between every gen swap or you are judging code that is not loaded.

**Landed and gated (2026-09-07):** the membership door (§2.0 — `Swarm_peers` / `Swarm_pier_retired` /
 `Swarm_pier_granted`, six call sites, DoorFace stated-once), reach terminality (§4.0), and the unit gate
  (§7.5: 25 assertions, no runner) plus the Book gate (every ceremony/social/pool Book green, caveat 0).
   Raw evidence + the sweep that found most of this was already ruled: `Fallen_out_of_mind_todo.md`.

**The slog, in order:**
1. ~~**The sweep**~~ — **DONE 2026-09-08 night, and it was SEVEN sites, not ~120.** The count was the
    error: **most `o({Pier:1})` in this repo is not membership at all.** Three shelves wear that mainkey,
     legitimately, because identity is per-shelf:
    - `Swarm_peering(ident).o({Pier:1})` — **membership**. The sweep's whole subject. Seven sites.
    - `w.o({Peering:1})[0].o({Pier:1})` — the **transport world's** piers: the Lies editor/runner channel
       and Peeroleum's carriers (Peeroleum 7 · LiesLies 6 · LiesFunk 4 · Tribunal 2 · Tyrant · RemoteWormholeNav).
    - `H.Awo('Bearing').o({Pier:1})` &c. in **`MachPeerily`** (17) — live p2p `Pier` *instances* from
       `p2p/Peerily.svelte.ts` standing in machine-test worlds. Not particles about friends at all.
    Converting either of the last two to `Swarm_peers` would be a **bug**, not a tidy. Anyone re-counting
     this must split by the container first; a grep for the mainkey answers the wrong question.

    **The seven, and the question each turned out to be asking:**

    | site | question | why |
    |---|---|---|
    | `Radio_friendly` | `{live:'all'}` | naming a peer is not a permission — a lapsed grant must not collapse a friend's name to a hex prefix |
    | `Riffle_homes` | `{live:'all'}` | the shelf is mine, the name is theirs |
    | `Radio_lineup_errors` | `{live:'Music'}` | "the wire owes us their music" is only true of someone who granted it — deleted a hand-rolled `Swarm_pier_live` under a raw walk |
    | `Presence_ask_roster` | default | transport: a nascent pier is exactly who presence must ask about; a retired one gets nothing |
    | LiesFunk `crew` · `dump` · `tidy forget:` | `{live:'all'}` ×3 | see the ruling below |

    **THE RULING THIS SWEEP PRODUCED — the divide in one line:**
    > **The app asks who is LIVE. The debug surface asks what is THERE. Never swap them.**
    A diagnostic that filters retired rows is *precisely how* a Cave that was a closed browser window
     stayed invisible for 36 hours (§1). The faces that hid it were being helpful. `crew`, `dump` and
      `tidy forget:` therefore take the ledger deliberately — and `forget:` **must**, since a door that
       can only see live piers cannot tidy a dead one.

    **Six of the seven are provably no-ops** (`Swarm_peers(ident,{live:'all'})` is `return all` — the
     identical array; `{live:'X'}` is exactly the hand-filter it replaced). The one real behaviour change
      is `Presence_ask_roster`, which now excludes retired piers. That matters when reading the Book gate.

    ✅ **RESOLVED — MusuHeist's caveat volatility is NOT the sweep, and was never new.** Recorded in full
     because two of my own claims along the way were wrong and the retelling would repeat them.
     **What was measured:** three pinned runs on a quiet, freshly-reloaded, contention-free runner gave
      1 · 13 · 21 caveats, always `ok_pct 1`, 22/22, never a fail — and the onset crept monotonically
       earlier (13 → 10 → 2), each block running contiguously to the last step.
     **Why it is not the sweep, by construction:** the runner identity `da060c94` holds **zero piers**
      (`runner_ask crew` → `friend_piers:[]`, `link_piers:[]`, `bodies:[]`). `Presence_ask_roster` — the
       only one of the seven that can change a set — therefore filters an empty list either way. All seven
        conversions are no-ops on this runner. *(Bonus: that `crew` reply came back through the very op
         this sweep edited, so the LiesFunk change is live-proven too.)*
     **Why it was never new:** `SoundPooling_todo.md:57` already records it, 2026-09-07, before the sweep
      existed — *"MusuHeist 22/22 ok but caveat 1 on 20 steps — a broad PRE-EXISTING drift (it blankets
       handshake steps that touch no changed code)"*. Twenty steps then; thirteen and twenty-one tonight.
        Same phenomenon.
     ⚠ **MY TWO ERRORS, so they are not inherited.** (1) I called the baseline *"a fixed 4 caveats, every
      run"*. It was **one sample** — the baseline sweep ran MusuHeist once. A single run is not a
       distribution, and treating it as one manufactured a regression out of noise. (2) I wrote that
        MusuHeist "does not reach `Presence_ask_roster`"; it loads in every runner off the spine manifest.
         The claim happened to survive for a different reason (no piers), but the reasoning was wrong.
    **What is still worth someone's time:** the drift itself — a Book whose caveat onset creeps earlier
     across consecutive runs on one tab is accumulating state between runs, and nobody has ever chased
      that. It is a MusuHeist question, not a membership one. Old reasoning kept below for the record:
     ~~Three reasons to suspect otherwise~~, all recorded here so the morning does not
        re-derive them: (a) six of seven conversions cannot change a set — but the seventh is NOT out of
         reach, and this is the honest candidate: **`Ghost/N/Presence.g` is in the spine manifest**
          (`LiesLies.svelte:61`), so it loads in EVERY runner, and `Presence_ask_roster` fires on a ~10s
           **wall-clock** pulse regardless of what the Book is doing. A wall-clock verb whose result now
            depends on a membership filter, landing at a different point in a 22-step run each time, is a
             mechanism that would produce exactly a contiguous caveat block from a varying start. Against
              it: the pulse ran on the baseline too and the baseline was *stable*, so the change would have
               to make its output vary, which requires a retired pier in the Book world — check whether one
                exists before believing this. **Do not close this without checking it**; (b) a **second runner tab was
          live and being driven by another branch** (Voronation/LagoonStaple/VytoNestRest) throughout,
           and unpinned `runner_ask` lands on whichever tab answers first; (c) MusuHeist has a
            **documented settle-round flake** — `Heist.g:1338`, step 2's `see:` on two collections
             *"fires or does not depending on whether the world settles at round 5 or 6"* — and CPU
              contention from a second runner is exactly what moves a settle round. The caveats also ran
               in a **contiguous block from a varying start to the end**, which is the signature of one
                early divergence cascading, not of a logic change. `git diff` shows **0 dige lines**
                 changed in the fixture. ~~Next move: re-run MusuHeist ×3 on a single quiet runner~~ —
                  **done; (b) was falsified, the volatility survives a quiet runner. See the resolution above.**
2. ~~**`since`** (§4.2)~~ — **BUILT 2026-09-08 night; ONE FIXTURE RE-SWEAR OWED TO THE HUMAN.**
    Three edits in `Ghost/S/Swarm.g`: `Swarm_pier_entry` stashes `since` (guarded — a pier without one
     leaves the key absent, never `undefined` into sc); `Swarm_pier_stash` merges it **first-write-wins**,
      because the birth of a bond happens once and a re-seal, a `restash_all` mirror or a graft
       convergence must never move it forward; `Swarm_piers_rehydrate` restores it **after** the seal,
        since `Swarm_seal` stamps `Swarm_now` on an absent key — right for a new bond, wrong for one being
         stood back up. Seal's own `re_seal` read (3345) happens first and still sees the honest truth.
    **PROVEN on the runner:** SwarmReboot step 5 now reads `Pier,pub:648f0a13…,friendly:Mate,since:1751700000`
     while the world clock says `now=1751700030`. The bond kept its birthday across the reload.
    ⚑ **OWED — the human re-swears SwarmReboot `005.snap`.** Its fixture currently records the BUG as truth
     (`since:1751700030`, the re-stamp). Step 5 fails until it is re-sworn, and that failure is the fix
      working. Nobody but the human accepts a fixture.
    ⚑ **A SECOND BUG THIS INCIDENTALLY CURES, not previously noticed.** `Swarm_crew_view:451` computes
     `fresh = since && (now_ms/1000 - since) < 240` — the Door's glow marking *"the receipt of a finished
      link"*. Because a reload re-stamped `since` to now, **every bond looked freshly formed after every
       reload**, however old. The Door has been glowing four-minute-old receipts for months-old
        friendships, and nothing said so. It is honest now. Watch for a face that quietly depended on the
         old always-fresh behaviour.
    ⚠ Comment corrected in the same pass: `Swarm_radio_roll` justified itself with *"since does NOT survive
     a reload"*, which this change falsifies. **The roll still stands** and the reason was rewritten rather
      than deleted: `since` records when the BOND formed; the roll answers when I made the CHOICE. Two
       different events, and only the roll answers the second.
3. **The `%Card` migration** (`Fallen_out_of_mind §2.1`) — one mint, zero fixtures, but WAIT for the
    metaphysics agent's ruling on the three options first (one `%Card` with context-keyed prior · a distinct
     mainkey for the scratch catalog · keep `%Record` with mandatory `total`).
4. **Invite-as-rendezvous** (§8.10, `Crew_todo §6`) — the weld is ONE token field (`to`); the ceremony's own
    Book is green again so it is safe ground. Design first: consent must not become a third ask.
5. ~~**`Ra_pool_fill_homes`** picks the Cave with no liveness~~ — **DONE 2026-09-08 night, and it moved NO
    fixture.** `Swarm_body_pick` / `Swarm_body_for` take an optional clock; given one they prefer a `%Body`
     we have actually HEARD from. The signal already existed — `%Body.heard` is stamped on every inbound
      sibling frame (`Swarm.g:1469`) — and nothing had ever read it. This is the precise line §1 is about.
    **`away` is BORROWED, not invented.** `Swarm_crew_view` already calls a row *here* under 15s, *fading*
     under 45, *away* beyond, so the body the Door would draw as away is the one this pick steps over. One
      threshold, one meaning, in both places; a fresh number would have made the Door and the router
       disagree about the same body.
    **It PREFERS, then SPEAKS.** A stale Cave is still worth trying and silence is not — but a preference
     that falls back *silently* rebuilds the defect one layer down, the fill still going to a ghost and the
      log still reading like a slow peer. So the fallback says so, throttled to once a minute per identity:
       `🏊⚠ pool fill is drawing from a Cave we have not heard from (…) — it may be a closed tab`.
        **The bug was never that the wrong Cave got chosen. It was that nothing said so.**
    **Gate:** SwarmBody 23/23, MusuPoolFill 6/6, MusuPoolRandom 5/5, MusuPoolBytes 5/5, MusuPoolRadio 6/6,
     MusuReplica 14/14 — all caveat 0, and the new line appears in NONE of them (a Book passes no clock, so
      the away-check never fires). MusuHeist reached 22/22 `ok_pct 1` with no FAIL; its caveat count is the
       known drift and was deliberately not read as a signal. Unit: MembershipDoor 7/7, PoolKeep 6/6,
        ReachTerminal 5/5, TwoFounder 1/1.

6. **The protocols and their gates — WRITTEN, §3.4** (owner 2026-09-08: *"we also need to clearly present how
    those extra protocols are defined there, and how permissions work — a lot comes under 'Music' at the
     moment"*). Every `header.type` → handler → the ACTUAL gate expression, the grant vocabulary, the `runner_ask`
      ops by power. Five asymmetries surfaced (3.4.1) and `take`/`take_got` turn out unreachable over the wire.
       The next grant word (`Serve`? `Reach`? `Pool`?) gets decided in 3.4.2, not by another `'Music'` check.
7. **The debug surface is not behind the door (3.4.3).** `runner_ask` is dispatched pier-less at
    `Peeroleum_deliver_do:623` — no Pier, no signature, no inbox; tab-side gates are a `pub` prefix match, a lease
     that is refreshed but never checked, and the humdinger read-only rule. On a public relay that is an open
      introspection port (`crew` returns prepubs, grants and rebuffs). The rail to close it exists — sign the ask
       with the cluster key and verify tab-side as `ghost_compile` already does. File, then build; not tonight.

**Crew_todo comes with us.** The owner (2026-09-08): *"Crew_todo should come with us into this movement."*
 `Crew_todo.md` is the ONE living doc for membership words (crew · Cave · Captain · grant · charter · the theft
  tripwire's blindness · the epoch); this doc is the SURFACE between that substrate and the apps. Read them as a
   pair. Sibling rivalries are in an okay state: same-soul frames route, the alarm no longer screams at a Captain,
    bodies own their address; the one way left to run into yourself is two tabs on one identity (the relay door is
     first-come, the loser clamps bare). Open there: a second Captain is invisible to `Swarm_note_theft`.

**THREE BRANCHES, THREE FRONT DOORS** (owner 2026-09-08: *"code, infra, visual is the development branching
 I'm coming up with"* — after *"it's been far too one-track for the last few weeks"*). This doc is **infra**'s
  door, paired with `Crew_todo.md`. Code|metaphysics reads `Fallen_out_of_mind_todo.md` + the metaphysics brief.
   Visual reads the new **`Meaningfold_todo.md`** (the glass folds at the meaning and says everything it holds;
    working at `ulative/visualisation-2026-09-08/findings.md`). What infra OWES visual: §3.4 is the census of
     what actually crosses, and the `'Music'` bundle it names is a picture waiting to be drawn — one grant
      covering streaming, gossip, routing and work-booking is exactly the kind of thing a glass makes obvious.

**Known reds you did NOT cause:** `LakeRace` (real, unguarded compile fix — `Lies_handover.md`), `Presence`
 (needs a relay). Everything else on the unit shelf is green. Diff the snap before alarming.

**The arc:** the social substrate (identity · pier · grant · presence · transport) is a *platform*,
 and Radio/Heist/SoundPool/Story are *apps on it*. That layering is real and mostly good — SP owns no
  transport of its own, and that is the design. But the boundary was never given a **surface**, so
   apps reach straight past it into the substrate's raw storage, and the substrate's own truths
    (*this peer is retired*) are invisible to everyone who didn't personally remember to ask.

---

## 1. THE PRECIPITATING FACT (2026-09-06, eed831f1 measured live)

SoundPooling had not landed a track in ~36 hours. Every layer inside SP was fixed in turn — the
 preview carry, the disk resurrect, the pocket mirror, the byte-lane rebind, the eviction wipe, a
  `bin_rm` that called `bin_read`. All real; none of them the reason. The reason:

```
Body,pub:631300e8…,post:Cave        ← a closed Incognito window
Crew,soul:eed831f1…
  mate:631300e8…                     ← still crew
```

`Ra_pool_fill_homes` asks `Swarm_body_for(ident,'Cave')` for the crew Cave and draws circulation from
 it. eed's Cave was a browser window closed several sessions earlier. So every want, every reach and
  every `ws SEND` went to a ghost — six reaches still `dispatched` from 12:11 the previous night —
   while the daemon (alive, 40 records, Music granted both ways, a Pier on both sides) was never
    addressed once. It received nothing, so it never offered its catalog, so eed never mirrored it, so
     it could never even become a *candidate*.

**Nothing in the system said so.** A reach to a dead Cave is byte-identical to a reach to a slow one.

And the wider survey of the same account:

| finding | count |
|---|---|
| Piers total | 15 |
| …that are dead Incognito test windows | 13 (`Gur, Gruff, Green, Green, Gurf, Grink, Gurg, Gri, Garar, Grewp, Guatr, Grit, e4001fb6`) |
| …still live and real | 2 (`S` the daemon, `Grav` = eed itself) |
| Music grants revoked by eed | 13 — i.e. **the intent is already correctly recorded** |
| `owe:pier_accept` rows re-offered forever | 6 |
| Piers sharing one identical `since:` | 15 of 15 |
| retired-schema particles (`%Jam`, `%Like`, `%SoundPile`) | 0 — those migrations genuinely landed |

The rot is not old shapes. It is **live shapes holding dead references**.

---

## 2. THE DEFECT: the raw query is the API

`Swarm_pier_forget` (the Door's ✕) does the right thing: mints a signed `%NotGrant` per feature +
 UnInvites, and deliberately keeps the `%Pier` row *"as history — it is not deleted"*. Good.

But **"retired" was only ever implemented as a filter in one face**:

```svelte
// DoorFace.svelte
retired: !(Swarm_pier_live(p,'Music') || Swarm_pier_live(p,'MyCave')),
}).filter((f) => !f.retired)
```

Retirement is **computed on demand from grant state**, it is not **marked**, and only the Door ever
 computes it. Everything else walks the raw store:

- **126 direct `o({Pier:1})` call sites across 22 files** (`Ghost/{S,N,M,Story}`, `src/lib/O/**`).
- `Swarm_pier_live` exists but is an opt-in per-call grant check. Roughly **three** sites apply it.

So the substrate records "this relationship is over" in a signed, durable, correct way — and 123 of
 126 readers cannot see it.

> **The rule this violates.** A store is not an interface. If the only way to ask a question is to
>  walk the storage yourself, then every caller re-implements the domain logic, and the ones written
>   before the logic existed simply don't have it.

### 2.0 BUILT 2026-09-07 — and §2.1's proposed default was WRONG

`Swarm_pier_retired(pier)` + `Swarm_peers(ident, opts)` are in `Ghost/S/Swarm.g` (the membership-door
 region, beside `Swarm_pier_live`). Two things changed from the proposal below, both found by reading the
  call sites rather than the store:

**⚠ RETIRED IS NOT "NOT LIVE".** A `%Pier` with no live grant is one of two things, wanting opposite
 treatment:
- **NASCENT** — minted at hello/accept, grants not landed yet. It *needs* a transport route, or the
   handshake can never complete (`Swarm_station_routes` → `Swarm_reaccept_incomplete` is the one-way-pairing
    heal). §2.1's "default ⇒ live only" would have filtered these out and **wedged every new friendship,
     silently** — the worst kind of regression, since a Book that seals in one pass would still go green.
- **RETIRED** — it had a bond and the human ended it: a `%NotGrant` stands, or a link stamp was unlinked.

So retirement is decided on **positive evidence**, never on the absence of a grant, and the door's default
 is **not-retired** (live + nascent). A caller that truly means "granted for X" asks for the feature:
  `Swarm_peers(ident, { live: 'Music' })`. `{ live: 'all' }` returns the ledger.

**Name:** `Swarm_peers`, not `Swarm_piers` — the latter is already a stash key (`st.Swarm_piers`,
 `Swarm_piers_rehydrate`), exactly the collision §2.1's caution predicted.

### 2.0.1 THE SWEEP RULE — "does this caller want live, granted, or the ledger?" (2026-09-08)

Every raw `o({Pier:1})` answers one of FOUR questions implicitly, usually by accident. Made explicit:

| ask | `opts` | the question | who asks it | nascent? | retired? |
|---|---|---|---|---|---|
| **not-retired** | *(omitted)* | who might I be in a relationship with right now? | **transport** — a route, a greeting, a heartbeat | **in** | out |
| **granted for X** | `{live:'Music'}` | who may do *this* with me? | **a feature** — offer a catalog, serve bytes, expect music | out | out |
| **granted for anything** | `{live:true}` | who is an actual friend? | a badge count, a roster of real bonds | out | out |
| **the ledger** | `{live:'all'}` | what is the history? | an audit, the Door's show-retired, a migration | in | **in** |

(`{live:true}` was in §2.1's proposal but fell through to the default until 2026-09-08 — a different
 question wearing the default's answer. `Swarm_pier_granted` now states it once; pinned in the spec.)

**How to decide at a site — ask what breaks if you are wrong in each direction:**
- Including a **retired** peer would pester someone who left → at least not-retired.
  (`Swarm_pulse_all`, `Swarm_hi_all`.)
- Excluding a **nascent** peer would break a handshake → the default, never a feature filter.
  (`Swarm_station_routes` — filtering to granted-only would have wedged every new friendship.)
- Including a **nascent** peer would claim a capability that does not exist yet → the feature.
  (`Swarm_expect_friends` — armed *"a friend came online"* for a deleted peer.)
- Filtering at all would hide history → the ledger. (`Swarm_dial_piers`, `Swarm_probe_arrival`.)

**The errors are asymmetric, and that settles a close call.** Over-filtering (dropping a nascent pier)
 breaks *silently and permanently*: the handshake never completes, nothing logs, and a Book that seals in
  one pass still goes green. Under-filtering (keeping a retired one) is noisy but self-announcing — pointless
   frames at a dead door, which is exactly how the 36-hour Cave was eventually spotted. **In doubt, take
    the default. It fails loud rather than quiet.**

⚠ One UX consequence to own: DoorFace now uses not-retired, so a **nascent pier shows in the Door** while
 it seals ("a friendship becoming"). If the owner prefers the Door to list only actual friends, that is
  `{live:true}` — one word, now available.

**Converted so far** (six sites; the rest of the ~126 are a later sweep). Chosen because a retired pier is
 rare-to-absent in a Book, so these are fixture-inert by construction — they change what happens to a bond
  the human ENDED, and nothing else:
- `Swarm_station_routes` — a friendship the human ended no longer gets transport re-minted. This is the
   36-hour dead-Cave, closed at its source.
- `Swarm_pulse_all` — no presence heartbeat at a retired bond (the pier-heal pestering in another costume).
- `Swarm_hi_all` — no rebirth greeting either. Nascent piers still greeted: the hi exchange is part of how
   a half-sealed pair finds each other.
- `Swarm_expect_friends` — **a real hole, not just noise.** It tested for the PRESENCE of a `Grant:'Music'`
   child, and a revoked friendship keeps its grant and adds a `%NotGrant` — so a peer deleted in the Door
    still armed *"a friend came online"* and the Butler waited on a ghost. Its own comment says to copy the
     Door's tell; the Door's tell is `Swarm_pier_live`, not the child. Now `{live:'Music'}`.
- `Swarm_radio_roll` — a retired friendship leaves the dial's roll.
- `Radio_alone_why` — `anyPier` counted retired piers, so the radio said *"your friends are offline"* to a
   human with no friends left. The function's own comment already named `anyPier` as its real flaw; this is
    the other half of that repair. The honest tag is now `alone`.
- Guarded everywhere: a world with no Swarm keeps the raw walk.

**And the companion goal met — retirement is now STATED ONCE.** `DoorFace` carried its own definition, and
 it was **narrower than the truth in two ways that HID LIVE ROWS**: it tested only `Music|MyCave`, so a
  **`MyCaptain` link rail** (the Cave that adopted a Captain — exactly §8.10's case) and a **`Crew`-granted
   pier with no Music** both read as retired and vanished from the Door. It now asks `Swarm_pier_retired`,
    with the old expression kept as an explicit fallback for a gen that predates the door. Bonus of the
     positive-evidence rule: a nascent pier mid-seal now *shows* in the Door, which is right — that is a
      friendship becoming, not one that ended.

**Judged and deliberately left:** `Swarm_dial_piers` / `Swarm_probe_arrival` are *diagnostic censuses* —
 an audit view wants the ledger, not the roster (§2.1's `{live:'all'}` case). `Swarm_ive_got_tally` and
  `Swarm_gossip_music` were already correct (below). `Peeroleum.g:568`'s sibling-admit wants a ruling.

**⚠ `since` (§4.2) was attempted and deliberately deferred**: the fix is to carry `since` in the pier stash
 and restore it on rehydrate, but `Swarm_seal`'s stamp is already guarded (`if (!pier.sc.since)`) — the
  re-stamp happens because rehydrate re-seals into a fresh tree. Fixing it **moves a fixture**: SwarmReboot's
   own snaps record the reload re-stamp as truth (`003.snap since:1751700000` → `005.snap since:1751700030`),
    and `Swarm_radio_roll`'s comment leans on "since does NOT survive a reload". Not a blind edit — it wants
     the Book running first, then a deliberate re-swear.

**Two claims in §3.2 were wrong** — checked in the code: `Swarm_ive_got_tally` and `Swarm_gossip_music`
 *already* gate on `Swarm_pier_live(p,'Music')`. The boast does not go to revoked peers. Left alone.

**Deliberately not converted:** `Peeroleum.g`'s sibling-admit lookup (`:568`) asks "do we know this soul at
 all" on a security-adjacent path where the real gates sit downstream — it wants its own ruling, not a
  mechanical sweep.

**VERIFIED ON LIVE ROWS TOO — `node scripts/door_census.mjs`.** The unit spec proves the rule against
 fixtures; this points the same rule at a RUNNING host's real `%Pier` rows via `/c`, no browser needed
  (the daemon is a live host running these ghosts, which is a verification path a missing runner tab does
   not block). It restates the rule independently rather than importing the ghost, deliberately: a second
    reading is what makes a disagreement meaningful — if the two ever differ on a real pier, one is wrong.
     It prints WHY per row, never a bare verdict. Read-only.
```
node scripts/door_census.mjs                       # the local jamserve daemon
node scripts/door_census.mjs http://host:9099 tok  # any host exposing /c
```
First run against the daemon (2026-09-07): **3 piers, 3 kept, 0 retired** — Antch and Agug plainly live on
 Music, and **Grav (eed) live on Music with `Crew` REVOKED**. That last row is the `retired means NOTHING
  stands` case occurring in production, not in a fixture: a Crew revoke must not retire a peer still
   granted Music, and it does not. The safety direction is the one that matters — the new predicate retires
    nobody the old reading kept, so the door cannot drop a live friend.
⚠ Worth an owner's eye, surfaced by the census and not previously noticed: **the daemon holds eed as a
 Music FRIEND with its Crew grant revoked.** `Ra_pool_sources`'s `crewish()` therefore ranks eed as a
  friend, not crew — which is a live input to pool candidate ranking and to "a Cave pools by default".

**GATED, without a runner — `scripts/MembershipDoor.spec.ts`, 7/7 green.** The door is pure logic over
 particle children, so it needs no runner, peer, wire or clock: mount the real compiled `Swarm.go` on a
  stub House (the `SupplyGuards.spec` trick, whose own preamble names this exact bottleneck) and call the
   verbs against fixture particles. **This is the frontier claim in miniature (§7)** — a substrate
    predicate drilled with no social world standing at all, which is what the whole separation is *for*.
     What it pins: nascent ≠ retired (the wedge §2.1 would have caused); retired means NOTHING stands, so
      a Music revoke leaves a Crew pier live; a `MyCaptain` rail is live (the Door bug); an unlinked stamp
       retires on its own evidence; a revocation aimed at another pair does not retire this bond; and the
        three `opts` modes, with `[]` never null. Run it:
```
node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MembershipDoor.spec.ts
```
Read it as *"the predicate says what it means"*, never as *"the membership sweep works"* — the wiring
 claims (does a retired pier really lose its route? does the Door really hide it?) are Book claims.

## ✅ THE BOOK GATE — RUN AND GREEN (2026-09-07, runner da060c94 reloaded onto the new gen)

Ran once a runner tab appeared. **Every Book the door could plausibly break is green, caveat 0:**

| Book | result |
|---|---|
| SwarmStaple · SwarmPolicy · SwarmSteal · SwarmCohort | ok, 8/8/6/6, **caveat 0** |
| InvWalk · InvSeal · InvFerry | ok, 8/5/6, **caveat 0** |
| **SwarmBody** (the roster/body substrate, 23 beats) | ok, **caveat 0** |
| SwarmReboot | ok, 5, **caveat 0** |
| MusuPoolFill · PoolBytes · PoolRandom · PoolRadio | ok, 6/5/5/6, **caveat 0** |

**Two reds/caveats investigated, both PRE-EXISTING — proven by restoring the generated ghosts to HEAD,
 reloading the runner, and re-running:**
- **`SwarmInvite` fails steps 4–5** — *identical at HEAD*, and then diffed: the entire difference is the
   fixture recording `friendly:` as an empty string where the code correctly omits the key. The seal and
    the spent-nonce tooth both HOLD in the live snap. A two-line fixture re-swear, not a broken door. See
     `Crew_todo`. (My first read called it unguarded off an `ok:false` alone — diff the snap before alarming.)
- **`SwarmShare` caveat 8** — *exactly 8 at HEAD too*. Pre-existing fixture drift.
- **`MusuHeist` caveat count is RUN-VOLATILE and carries no signal**: measured 13 at HEAD, then **17 and
   then 1 on the SAME gen back-to-back**. Do not read it as a diff. (`runner-steps-dige-is-run-volatile`
    said so; this is the demonstration.) `ok:true` throughout.

Method worth reusing: back up the generated `.go`, `git checkout --` them to HEAD, reload the runner, run,
 then restore and byte-compare. It is the only way to tell "my diff broke it" from "it was already red",
  and twice today the answer was the second one.

⚑ **superseded — the gate below was owed and is now run:** compiled and esbuild parse-gated, and the Books have NOT run — no runner tab was booted
 (`runner_ask runners` shows only music pages). The ceremony family is what this could break:
  **SwarmStaple · SwarmInvite · SwarmPolicy · SwarmSteal · SwarmCohort · InvWalk · InvSeal · InvFerry ·
   SwarmBody · SwarmShare · SwarmReboot · MusuHeist**, then the pool set. Run these before trusting it.

### 2.1 The accessor (the original proposal — superseded above)

One named door, with the default that is safe:

```
Swarm_piers(ident, opts)      // opts: { live: 'Music' | 'MyCave' | true (any) | 'all' }
```

- default (`live` unset) ⇒ **live only** — a retired Pier is not returned.
- `{ live: 'all' }` ⇒ history included, for the two or three readers that genuinely want the ledger
   (an audit view, the Door's own "show retired", a migration).
- Companion: `Swarm_pier_retired(p)` as the single definition of retired, so it is stated once.

Then the sweep is mechanical: every `o({Pier:1})` becomes `Swarm_piers(ident)` unless it can say why
 it wants history. **Yes, all the tests would roll** — the owner said so before I did. That is the
  cost, and it is worth paying once rather than continuing to pay it in dead-peer bugs.

⚠ **Naming caution.** `Swarm_piers` must not collide with the stash pillar verbs
 (`Swarm_restash_piers`, `Swarm_pier_stash`, `Swarm_pier_unstash`) — those are about durability, this
  is about membership. Check before minting the name.

### 2.2 Why an accessor and not a delete

The owner asked directly: *"we can't keep revokes|UnGrants around without keeping the central
 Peering/Pier for it as well?"* — correct, and keeping them is right: a `%NotGrant` is a signed
  statement *about a relationship*, and it needs the relationship's particle to hang on. The fix is
   not to delete history; it is to stop conflating **the ledger** with **the roster**.

---

## 3. WHAT FLOWS ACROSS THE BOUNDARY (and what each gets wrong today)

The substrate offers four things upward. Apps consume all four, mostly by reaching past the boundary.

| substrate offering | the app-facing seam | what crosses it | current defect |
|---|---|---|---|
| **Membership** — who my peers are | `Peering.o({Pier:1})` *(raw)* | Radio sources, Heist routing, Reach addressing, the Door | retired peers returned as live (§2) |
| **Authority** — what they may do | `%Grant` / `%NotGrant`, `Swarm_pier_live` | Music sharing, MyCave, Crew | correct, but only read at ~3 of 126 sites |
| **Presence** — who is here now | `p.c.heard_at`, `Swarm_socket_fresh` | the catalog offer gate, reach dispatch, the dial's live filter | conflated with membership: a peer that is *gone* and one that is *quiet* are the same shape |
| **Transport** — get a frame there | `Swarm_deliver` → `Peeroleum` → relay | every app frame | a deliver to an unroutable peer returns `false` **silently** |

### 3.1 Repli — the one we encourage, and how SP sits on it

SP owns **no transport**. It rides Repli twice, both times *through Heist*:

- **catalog** — `Ra_offer_stock` ships each Mag as a husk fragment → `Repli_merge` dedups far-side →
   mints the `%Theirs` mirror that `Ra_pool_sources` draws candidates from.
- **bytes** — `%Heist,into:pool` → `Heist_keep_step` → `Repli_register_caster`/`_rx` → chunk wants.

This is the intended shape ("no second lane") and it is why a Pier-level or presence-level fault
 *presents as* "SoundPool is broken". The layering is sound; the diagnosis is what is missing.

**The catalog offer is presence-gated** (`Swarm.g`, the share beat):

```
if (!p.c.heard_at || (now - p.c.heard_at >= 40000 && !Swarm_socket_fresh(p, 20000))) continue
```

*"husking at silence is litter"* — reasonable. But combined with §2 it produces a **silent circular
 starvation**: a peer you never hear from is never offered a catalog; with no catalog it is never a
  candidate; never a candidate, you never address it; never addressed, it never hears from you. Two
   live, mutually-granted bodies can sit forever, each waiting for the other to speak first. That is
    eed↔S today.

→ **Owed:** a presence *floor* for a sealed, granted, currently-connected peer — offer at least once
   per N minutes regardless of `heard_at`, the same way the re-offer floor already backstops the
    change-mark. (`swarm_offer_floor_ms` exists for the mark; this is the other half.)

### 3.2 The systems that walk membership, by name

Each of these currently treats a retired Pier as a peer:

- **`Swarm_station_routes`** — re-mints a transport route for every Pier at standup, retired included.
- **the pier heal / `%owe` ledger** — re-offers `pier_accept` to retired piers forever (eed: 6 rows).
- **`Swarm_boast_floor` / `ive_got`** — boasts a collection at peers who revoked.
- **the share beat's offer loop** — gated on `Swarm_pier_live(p,'Music')`, so this one is **correct**;
   it is the model for the rest.
- **`Ra_pool_sources`** — reads `%Theirs` mirrors, which are minted from offers; inherits whatever
   membership decided upstream.
- **`Ra_pool_fill_homes`** — `Swarm_body_for(ident,'Cave')`, the crew Cave. **No liveness check at
   all** — this is the one that cost two days.
- **Reach addressing** — `Swarm_reach_addr` resolves a role or an address with no liveness question.

### 3.3 THE TWO ARMIES — the interface as arrayed language (2026-09-07)

Two vocabularies face each other across one frontier. The LEFT army knows *who may act and how a
 frame reaches them*; it never names a song. The RIGHT army knows *what a track is and how its bytes
  move*; it never mints a key. The war is won or lost in the thin no-man's-land between them — which is
   also the only ground no test currently stands on (see §7).

```
              THE SOCIAL ARMY                        ║                 THE APP ARMY
   substrate — WHO may act, HOW a frame crosses      ║      music — WHAT a track IS, how its bytes move
 ──────────────────────────────────────────────────╫──────────────────────────────────────────────────
  Identity · prepub · soul                           ║  Record (the holding)  ·  Card (catalog listing)
  Crew · mate · role:Captain|Cave                    ║  Mag · Cloud   (the magazine, offered as a husk)
  Grant:Music|MyCave|Crew    ·    NotGrant           ║  Preview · Prehead · Stream   (opus — PARTIAL stream)
  Pier (a peer) · Peering                            ║  Original | Lossy   (%Body whole-file chunks — REAL)
  Body,post:Cave (a device) · humdinger              ║  keep-id = sha256(pub | base | path)  (deterministic)
  heard_at · socket_fresh    (presence)              ║  RummageLib · rummage id   (path-hash of a describe)
  era · voucher    (rebirth · revocation)            ║  seed (the Mine id) ──re:──▶ the lofi twin (ogg128)
  Reach: booked→dispatched→serving→arrived→landed    ║  Heist keep: wanted→choosing→pulling→done
             ·  refused | dead                       ║        Pick :  blag {re:seed}  |  wire {id}
  Peeroleum · Swarm_deliver · relay deliverLocal     ║  pool | Mine | Theirs   (the three homes)
             (the wire · the own-door rule)          ║  Repli :  want ─▶ page ─▶ land   (the transport)
 ══════════════════════════════════════════════════╩══════════════════════════════════════════════════
     ▽  THE FRONTIER  ▽   where the two touch — and where every SP bug has hidden

   Ra_pool_fill ................ books a ........▶ Reach                (app asks the substrate to carry)
   Heist_rummage_ask/answer .... rides .........▶ Repli_offer          (consent-gated by Grant:Music)
   Repli_serve_want ............ consults ......▶ Repli_allowed        (Grant + pier — SOCIAL, mid-serve)
   Heist_materialise_one ....... mints .........▶ keep-id record       ◄── THE TWIN BUG LIVED HERE
   Repli_find_record ........... resolves ......▶ keep-id (husk|full)  ◄── THE SILENT SERVE LIVED HERE
   w.c.rummage_libs (APP state)  lifetime ruled by ▶ reload / era      (a SOCIAL event wipes app memory)
   Ra_pool_fill_homes .......... picks .........▶ Body,post:Cave       (app booking reaches for a device)
```

**Five places the treaty leaks** — each one a spot where an app decision cannot be made without a
 social fact, which is exactly what makes the app untestable in isolation:

1. **`w.c.rummage_libs`** is app state, but its *lifetime* is a social event — a reload or an era wipes
    it, and the holder then cannot resolve a keep-id it minted. (The re-census heal exists only because
     of this leak.)
2. **`keep-id`** folds a social fact (`pub`) into an app identity (`sha256(pub|base|path)`). The id a
    track is pulled by is half-social by construction.
3. **`Repli_serve_want`** reaches into `Grant`/pier (social) *mid-serve*, on every chunk want.
4. **`Ra_pool_fill_homes`** picks the crew Cave — a social body — with no liveness question. This is the
    one that cost two days.
5. **A pick's binding** (`blag {re:seed}` vs `wire {id}`) depends on whether a *real describe* ran —
    a live/social precondition. Get it wrong and the pull chases the opus preview forever (the 52/54
     stall). No fixture can be wrong about it because a fixture collapses the two id-spaces into one.

### 3.4 THE PROTOCOLS AND THEIR GATES (2026-09-08 census — every `header.type`, its handler, the ACTUAL gate)

Owner: *"we also need to clearly present how those extra protocols are defined there, and how permissions work
 (a lot comes under 'Music' at the moment)."* This is that presentation. Every gate below was read off the
  handler body, not inferred from its name. Line numbers are 2026-09-08; the shape is the durable part.

**3.4.0 How a frame reaches a handler.** The relay routes on `header.to` ONLY and never reads `from`
 (`Swarm.g:1490`). It binds an identity address on a signed `hello` alone (`relay.ts:624-628`, `verifyHeader`
  + 30s `ts` window); a `?addr=` bind is unauthenticated (`:568`). Then `Peeroleum_deliver_do` (`Peeroleum.g:595`)
   is a ROUTER, not a verifier, in this order:

| # | branch | line |
|---|---|---|
| 1 | `to:@channel` → per-Peering subs; no inbox, no ack | `:606` |
| 2 | `runner_ask` / `ghost_compile` → by TYPE, pier-less, no ack, no inbox | `:623` |
| 3 | `pier_hello` (and a granted non-link `pier_accept`) → handler-direct, `pier=null` | `:650` |
| 4 | `Peeroleum_same_soul` (`:541`) or `Peeroleum_crew_road` (`:556`) → pier-less dispatch | `:669` |
| 5 | no pier → DROP (`w.c.wire_drop`) | `:674` |
| 6 | `ack` → `Peeroleum_take_ack`, never inboxed | `:728` |
| 7 | ephemeral lane: `ping pong run_phase advertise swarm_hi pulse` | `:754` |
| 8 | `no_protocol` · `repli_want` · `ferry_want`/`ferry_cancel` (direct) | `:769-790` |
| 9 | everything else → `%req:unemit`, drained serially by `req_unemit` | `:796`, `:1140` |

**"Verified" in the inbox means exactly two things** (`req_unemit:1147-1162`): the pre-Ud gate (no `%Ud` on
 the Pier ⇒ only `hello|noop` pass; `%Ud` is set by `hear_hello` on a pubkey PREFIX compare, not a signature)
  and body integrity (`sha256(buffer) === body_hash` when present). **There is no `header.sign` check anywhere
   in Peeroleum.g.** Authenticity is the HANDLER's job: for the 24 swarm kinds it is `Swarm_arm`'s funnel
    (`Swarm.g:1423`): recipient = `Swarm_account_of`; the crew-claim/theft drop for `pier_hello|swarm_hi|pulse`;
     the VOUCHER gate (`sealed && station_up && type !== 'pier_hello'` ⇒ `Swarm_voucher_ok`, `:1497`); the reach
      lane's own voucher (`:1535`). `Peeroleum_on` writes `w.c.on[type]`; the inbox prefers it for anything but
       `hello|trust`; an unregistered type on a ready peer draws `no_protocol` back.

**3.4.1 The table.** "funnel" = the Swarm_arm gates above. Families: spine · social · music-app · ferry ·
 lies-control.

| type | handler | family | gate | does |
|---|---|---|---|---|
| `hello` | `hear_hello` Peeroleum:147 | spine | pubkey prefix-match | sets `%Ud` |
| `trust` | `hear_trust` :158 | spine | **NONE** | records `%heard` |
| `noop` / `ack` / `no_protocol` | :1175 / :728 / :769 | spine | pre-Ud exempt / pier / **NONE** | ack · retire emit · "peer lacks type" |
| `pier_hello` | `Swarm_hello` Swarm:2797 | social | Idzeug: `token_parse` · `prepub===mine` · `page_bound` · `iz_find` | first-contact seal |
| `pier_accept` | `Swarm_accept` :3011 | social | `page_bound` + awaiting-ceremony prepub match, or `verify_grant` | seals the pier |
| `pier_confirm` | `Swarm_confirmed` :3131 | social | `page_bound` + pier must already exist | reciprocal grant |
| `pier_reject` | `Swarm_rejected` :3101 | social | funnel; folds only own `awaiting` + pub match | books a rebuff |
| `reinvite` | `Swarm_reinvited` :3189 | social | `verify_reinvite` | routes a chain invite |
| `reinvite_honour` / `reinvite_seal` | :3232 / :3261 | social | `page_bound` · `verify_grant` · `for===my pub` · no escalation | seals B–C / reciprocal |
| `reinvite_ok` | :3288 | social | `verifyHeader(ok,[ok.pub])` + holder match | marks Idzeug spent |
| `crew` | `Swarm_crew_heard` :241 | social | **soul-signed** `verifyHeader` over the ledger + `verify_revoke` per not | replaces the ledger |
| `charter` | `Swarm_charter_heard` :7228 | social | funnel voucher; absorb verifies soul sig + highest era | absorbs family roster |
| `roster` | `Swarm_roster_heard` :7002 | social | **funnel only — plain rows, unsigned** | writes `%Body` rows |
| `swarm_hi` | `Swarm_heard_hi` :2687 | social | `page.prepub` + sealed pier must exist | epoch + presence |
| `pulse` | funnel :1545 | social | funnel voucher | `heard_at`, era |
| `reach` | `Swarm_reach_road` :6543 | social | rostered `%Body` prefix OR `Swarm_pier_live(p,'Music')` + `reach_vouched` | books work on me |
| `reach_done` | `Swarm_reach_ack` :6513 | social | funnel `reach_vouched`; handler matches (to,of,for), **no sender check** | settles my reach |
| `ive_got` | `Swarm_ive_got` :4469 | music-app | sealed pier OR crewmate, else rebuff | boast counts |
| `suggest` / `suggest_got` | :4142 / :4160 | music-app | sealed pier (+ id match) | mints / retires a `%Suggest` |
| `repli_ready` | `Swarm_repli_ready` :4595 | music-app | sealed pier + route; then `Swarm_pier_live(p,'Music')` | triggers a catalog offer |
| `repli_want` | `Repli_serve_want` Repli:946 | music-app | `Repli_allowed` → `Swarm_share_granted` → `Swarm_pier_live(p,'Music')` | serves a page |
| `repli_lines` / `repli_page` | :1172 / :1233 | music-app | `Repli_rx_ok(w,pier)` | merges mirror / stashes bytes |
| `repli_parked` / `repli_missed` / `repli_no_idspace` | :670 / :715 / :756 | music-app | **NONE** (pier arg dropped at :1516-1518) | suspends RTO / notes miss / terminal |
| `take` / `take_got` | `Heard_hand_land` / `_got` Heard:688/707 | music-app | **NOT REGISTERED** at Swarm:1802 — mail-path only | lands / marks a handed ♥ |
| `ferry` | `Swarm_ferry_park` :7672 | ferry | funnel voucher only, no from-check; consume needs human + `#fc` | parks a sealed account |
| `ferry_want` | funnel :1593 | ferry | `Swarm_pier_linklive` (MyCave∥MyCaptain) + secret + serial + not ferrying | re-raises the confirm |
| `ferry_cancel` / `ferry_held` | :8251 / :1668 | ferry | phase + `pubmatch(from)` / own phase `sent|held` | folds "connecting…" / delivery ack |
| `ferry_got` | funnel :1682 | ferry | `top.c.humdinger \|\| top.c.consenter` | closes ceremony, hands helm |
| `rungo` / `become_book` / `ghost_ledger` | LiesLies:889 / LiesFunk:1981 / LiesLies:987 | lies-control | **role-only** (runner) + pier | run authority / drive a Book / replace ledger |
| `run_result` / `run_phase` / `advertise` | LiesFunk:3772 / :3803 / LiesLies:1808 | lies-control | role-only (editor); `advertise` **NONE** | outcome / blip / runner roster |
| `ghost_compile` | `Lies_ghost_compile_recv` LiesLies:831 | lies-control | **soul-signed**: `verifyHeader(…, browserTrustedPubs())` | forces a dock compile |
| `grant_offer` | LiesFunk:596 | lies-control | `prepubOf(atom.for)===me` + issuer+sig verdict | installs a `%Grant` |
| `wormhole_beg` / `wormhole_req` / `wormhole_reply` | :616 / :662 / :837 | lies-control | **NONE** / `verify_grant`+`to==='remoteWormhole'`+`by===idento.pub` / corr match | disk access ask / serve / bytes back |
| `ping` / `pong` | LiesLies:1555 / :1631 | lies-control | **NONE** | heartbeat |
| `runner_ask` | `Lies_runner_ask_recv` LiesFunk:2489 | lies-control | see 3.4.3 | the CLI control plane |

**Asymmetries the table makes visible** (a gate missing where a sibling has one): `repli_parked|missed|no_idspace`
 take no pier while `repli_lines|page` check `Repli_rx_ok`; `wormhole_beg` is open while `wormhole_req` verifies a
  grant; `roster` writes `%Body` rows unsigned while `charter` demands a soul signature (the roster is a routing
   cache — see `crew-answers-not-the-roster` — so unsigned is arguably fine, but say so); `take`/`take_got` are
    dispatched at `:1585` but absent from the registration array at `:1802`, so a handed ♥ cannot arrive over the
     wire at all.

**3.4.2 The grant vocabulary.** ONE reader: `Swarm_pier_live(pier, feature)` (`Swarm.g:5485`) — a link-stamp
 arm (`pier.sc.link && !unlinked && post === post_from_feature(f)`, no `NotGrant`), else `Grant:feature`
  particles minus a matching `NotGrant` by `(by, for)`.

| Grant | issued by | unlocks | revoked at |
|---|---|---|---|
| **`Music`** | mutual mint at `Swarm_seal` (`:3364`) from an `?Iz` invite; crew-shared at `Swarm_accept` | the WHOLE Repli transport (`Repli_allowed` every leg) · `Swarm_gossip_music` · `ive_got_tally` · `Swarm_offer_now` · `share_beat` · `serve_ask` · the friend arm of **`reach`** (`:6557`) · `Radio.g:2083,2354` · `Swarm_dial_piers` (`:1136`) · `Swarm_probe_station` (`:1194`) · `Swarm_pier_granted` | `Swarm_revoke` (`:5402`) → `NotGrant`; `Swarm_pier_forget` revokes every feature |
| **`Crew`** | the Captain's soul key, `Swarm_crew_grant` (`:114`), homed on `/Crew/mate` | the cert-crew road in `Swarm_voucher_ok` · `pier_granted` · `pier_retired` · `Swarm_station_routes` | soul-signed `NotGrant:'Crew'` via `Swarm_crew_eject` (`:335`), absorbed in `crew_heard` |
| **`MyCave`** / **`MyCaptain`** | the link ceremony (`LinkDevice.svelte:222` → `Swarm_ferry_link`), sealed at `Swarm_accept`'s link arm | `Swarm_pier_linklive` (`:5510`) ⇒ `ferry_want` service, `ferry_poke`, confirm parking; `MyCaptain` drives the helm hand-over at `ferry_got` | `Swarm_cave_unbond` (`:5618`); tombstone read at `:1645` |
| **`link`** | not a Grant — the chrysalis STAMP `pier.sc.link=1, post` at `Swarm_seal:3375` | first arm of `pier_live` / `pier_linklive` | `pier.sc.unlinked` |
| **`remoteWormhole`** | the editor's cluster idento (`Grant.ts`) | `wormhole_req` serve | `NotGrant` check is a TODO (`LiesFunk:716`) |

**The `Music` bundle — the thing the owner named.** `'Music'` is the hardcoded gate for things that are not
 music: the whole Repli transport, presence dialling, station probing, boast tallies, AND cross-node procedure
  booking (`Swarm_reach_road:6557` — "the same Music grant that lets it stream from me lets it ask me to
   press"). One friendship grant confers streaming + gossip + transport routing + remote work-booking together.
    The fix is not more `'Music'` checks; it is deciding the next WORDS (candidates: `Serve` for repli legs,
     `Reach` for work-booking, `Pool` for SP circulation — each a `Grant:<word>` minted at the same seal, so a
      revoke can be partial) and declaring them HERE before any handler checks them. §2.0.1's `{live:'X'}` is
       already shaped for it.

**3.4.3 `runner_ask` — the ops by what they can do, and the exact gate.** Common preamble for every op
 (`LiesFunk:2493-2517`): `corr` + `op` required; the optional `ask.pub` self-filter; `Lies_engage_touch` —
  which REFRESHES the lease, never checks it. `client` is a self-asserted string. No signature, no grant.

| group | ops | gate |
|---|---|---|
| read-only introspection | `reactap ping probe console minisnap world state supervisor rungos steps snap diff snaps trace assertions shot why svg face crew atlas_* electrode dump` | **NONE** beyond the `pub` filter — any tab, any relay socket, a humdinger included |
| run-driving | `run release retain accept declare` | `ro_only` refusal (humdinger ∧ ¬runner); `run` also `Lies_engage_check` (the don't-steal lease, 10 min TTL, any client may name itself) |
| mutating the account | `tidy` (crew · rebuffs · forget:<prefix> → `Swarm_pier_forget` mints signed NotGrants) · `poke` (hardcoded `POKES` allowlist) · `socklog` | `tidy`: `socklog_armed()` IS the consent + a live self; `poke`: allowlist; `socklog`: reload only if `Lies_is_runner` |
| code-loading | `ghost_load` · `reload` | `ro_only` refusal; `ghost_load` path-bound `/^Ghost\/[A-Za-z]+\/[A-Za-z_]+\.g$/` (only a `.go` the compiler already wrote); `reload` runner-only |

Upstream of all of it, code lands via the relay's `gen_write` (`relay.ts:711`): with `CLUSTER_TRUSTED_PUBS` set
 it demands `body_hash` + `verifyHeader(header, trusted)`; unset it warn-and-allows — the relay's own comment
  calls it "the relay's one RCE surface". `@channel` names are first-come; `who` answers only a hello-bound socket.

**What this section decides.** (1) The debug plane is a fourth army — not spine, not social — and its gate
 today is REACHABILITY of the relay. On localhost that is the machine; on djamsend it is the internet. The rail
  to close it exists (`ghost_compile` already does it: sign the ask with the cluster key, verify tab-side against
   `browserTrustedPubs()`); the read-only group can stay open on a LAN relay by policy, but say so in one place.
    (2) No handler checks a signature in the spine — the voucher gate in `Swarm_arm` is the whole of wire
     authenticity, so a new social kind MUST register through `Swarm_arm`'s array (`:1802`) or it is either
      unreachable (`take`) or ungated. (3) The next grant word is decided in 3.4.2, not by another `'Music'`.

---

## 4. TWO REPAIRS THAT STOP THIS HIDING AGAIN

### 4.0 GATED 2026-09-07 — `scripts/ReachTerminal.spec.ts`, 5/5, no runner

The three repairs below are pure logic over particles, so they gate without a relay. What it pins:
- **gone is LEDGER-based, never presence-based** — a live `Music`/`Crew`/`MyCave` grant or a crew row keeps
   a target alive, and a friend who is merely *offline* is explicitly not gone. If this ever starts reading
    `heard_at`, a quiet friend's reaches begin dying and the bug inverts; the test says so out loud.
- **a target nothing vouches for IS gone** — and that is the main case, not an edge one: ejecting the dead
   Cave removed its row, and that absence is what finally let its reaches die.
- **two non-answers stay 0** — an empty `to` and a missing reach are malformed questions, not dead targets.
   Answering "gone" to a malformed reach would let a booking bug quietly mark healthy intents dead.
- **all three terminals stand still** — `arrived | refused | dead` never re-dispatch and are not mutated on
   the way out (the guard used to test `arrived` alone, so a refused reach re-sent every pass and flipped
    itself back to `dispatched`, dodging its own receipt sweep).
- **the cap counts standing work, not receipts** — a shelf of three corpses still admits a new booking,
   while three *standing* reaches correctly refuse the fourth, and re-booking an existing reach is always
    honoured. This is the 32/32-with-eleven-corpses shape, pinned.

Writing it caught a bad test of mine, not bad code: a case named "an unknown target is not declared gone"
 asserted only the empty-and-null inputs and passed vacuously. The real behaviour is the opposite, and it
  is the point of the feature. **A green test whose name contradicts its assertions is worse than no test.**

### 4.1 A reach must be able to die

Today: `booked → dispatched → serving → arrived → landed`, plus `refused | dead` as terminals that
 **only a peer's answer** can produce. So a reach to a body that no longer exists has no path to a
  terminal state: it re-dispatches (with backoff) forever, holds a pool want-slot forever, and reads
   in a snap exactly like a reach to a peer that is merely slow.

→ **Owed:** on dispatch, if the target resolves to no live pier and no crew body, mark
   `state:dead, why:'no such body any more'`. It is already the shape `Ra_pool_fill_land` uses for its
    other misses (`why` stamped on the row, said once). eed has six rows that want this right now.

### 4.2 `since`, and timestamping generally

All 15 of eed's Piers carry `since:1788658356` — the last standup. The field is re-stamped on
 rehydrate rather than preserved, so **age information does not exist** anywhere in the roster. The
  owner: *"%since and general timestamping could do with a do up."*

This is not cosmetic. Age is the cheapest possible liveness heuristic and the natural sort for a Door
 roster, and its absence is exactly why thirteen dead windows and one dead Cave could sit unnoticed
  among two real peers.

→ **Owed:** `since` set once at seal and preserved across rehydrate (it rides the pier stash already);
   audit the same class of field elsewhere (`at`, `heard_at`, `offered_at`) for reset-on-reload.

---

## 5. WHAT THIS DOC IS NOT

- Not a proposal to delete retired Piers. History stays; §2.2.
- Not a claim the layering is wrong. SP-over-Heist-over-Repli is the right shape and should stay.
- Not a rewrite of the substrate. Every repair here is additive: one accessor, one terminal state,
   one preserved field, one presence floor.

## 6. MAP

- `Swarm_spec.md` — the canonical social spine (identity, contacts, invites). The *what*.
- `Sharing_design.md` — settled consolidation of the sharing spine; `[LIVE]/[BOOK]/[OWED]` honesty marks.
- `Network_procedures_todo.md` — builder-facing recipe for a multi-party feature. **This doc is its
   missing half**: that one says how to *build* on the substrate, this one says what the substrate
    *owes* a builder.
- `Pier_todo.md` — the KINDS of Pier (friend / own body / role). Retirement is a **state orthogonal
   to kind**; the accessor in §2 should be designed alongside that split, not after it.
- `Peeroleum_spec.md` — transport, routing, the no-Pier drop.
- `Repli_design.md` — replication, the offer/merge lane §3.1 leans on.
- `Crew_todo.md` — the crew ledger, `Swarm_crew_eject`, and who may write membership.
- `SoundPooling_todo.md` — the app that paid for this doc.

---

## 7. WHERE THE TESTS STAND ON THE FRONTIER (2026-09-07 — the twin-record bug's autopsy)

The reason the twin-record + silent-serve bug (SoundPooling_todo §0, 2026-09-07) survived a green
 sweep for days: **every Book draws its line of reality to include only ONE army, and the bug lived in
  the no-man's-land between them.** Measured, not guessed — reading the Book source:

| Book | social army | app army | Repli transport | can it reach the seam? |
|---|---|---|---|---|
| **MusuPoolFill** | real (reach lifecycle, grants, doer) | **mocked** — hand-mints the mirror `{Record, id:'o1'}`; inspects `cave_writes`/`cap_writes` | **stubbed** | no — the mirror id *is* the seed; no rummage space |
| **MusuPoolBytes** | thin | real record, real `Heist_land` to disk | **skipped** — lands an *already-full* local record; never pulls | no — no want, no materialise |
| **MusuReplica / Repli\*** | thin | **clean fixture records (id == record)** | **real** | no — never a describe-minted keep-id, never a husk twin |
| **MusuHeist / MusuVend** | real (piers, grants, offers) | real magazines | **real** (`Repli_offer`, wants) | no — offers whole records; no rummage→materialise→pull |

So: **SP's own Books do not exercise Repli** (they mock or skip the chunk transport). **Repli's own
 Books do not exercise the rummage/keep-id/materialise path** (they use clean records). Real SP needs
  *both at once*, and no Book stands there. That is the seam, drawn on the map in §3.3.

**Realisticising the repro Book** — moving one Book's reality line DOWN to cover the frontier. It must
 stand up *just enough* of both armies for the app path to run for real:

1. A holder with a real folder (a mock nav dir of ≥2 tagged files) and a **real describe** —
    `Heist_rummage_folder` / `Heist_census_heads` — so genuine **rummage keep-ids** get minted beside
     the seed, in a `RummageLib`. (This is the app-army reality the pool Books skip.)
2. A **real Repli crossing** — `Repli_arm` + `Repli_register_caster`/`_rx` over a mock Pier with a live
    `Grant:Music` — so `Repli_serve_want` → `Repli_find_record` → `Heist_materialise_one` actually run.
     (This is the transport the pool Books stub.)
3. A pool keep (`into:'pool'`, `lofi`) whose seed is the folder's heard track, wearing `re:seed`.
4. Pump beats, then **swear two claims at once**:
   - `%see:'a pool keep solos to one pick and reaches pulling'` — the asker binds by `re:seed`.
   - `%see:'the holder serves the lofi copy it materialised — never a chunkless husk and never the opus preview'`
      — the second half nobody asserted. Watch it via the mirror record gaining `%Original` chunks, and
       (the bug's exact signature) that `Repli_find_record` never returns a `total:0` twin.

The mock Pier is where the "line of reality" is drawn. Today it sits *above* the rummage id-space and
 *above* the transport; this Book pulls it *below* both. Everything left above the line (the relay's
  own-door rule, the era/voucher machinery, a live AudioContext) stays mocked — those are genuinely the
   substrate's own to test, and §3.3's frontier says exactly where the cut is clean.

**Then the interface repair (§2, §4) makes the cut permanent**: once `Swarm_piers({live})`, a terminal
 reach, and a keep-id that does not fold `pub` in are in place, the app army can be drilled against a
  fixture holder with *no* social world at all — and this whole class becomes a five-line unit test
   instead of a Book that has to raise two armies to catch one deserter.

---

## 7.5 THE SEAM GATE — 24 assertions, four specs, no runner (2026-09-07)

Every repair this session made to the frontier is pure logic over particles, so the whole set gates with
 no relay, no peer, no wire and no clock. **This is §7's thesis, executed**: the app army drilled against
  fixture particles with no social world standing. Run the lot:
```
node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs \
  scripts/MembershipDoor.spec.ts scripts/ServeResolve.spec.ts \
  scripts/ReachTerminal.spec.ts scripts/PoolKeep.spec.ts
```
| spec | pins | reachable by a Book? |
|---|---|---|
| `MembershipDoor` (7) | retired ≠ nascent; retired means *nothing* stands; a `MyCaptain` rail is live | partly |
| `ServeResolve` (6) | the twin (prefer bytes, order-independent); the silence (`0 < 0`); presence is fill state | **no** |
| `ReachTerminal` (5) | gone is ledger-not-presence; three terminals stand still; the cap counts standing work | partly |
| `PoolKeep` (6) | browsed husks are not candidates; the rummage-id alias solos via `re:<seed>` | **no** |

Two of the four classes are **structurally invisible to fixtures** — a Book hand-mints its mirror, so a
 record's id IS the seed and the two id-spaces collapse into one, which is precisely why these bugs
  survived a green sweep for days. The unit layer is not a lesser Book; it reaches somewhere Books cannot.

Read every green as *"the predicate says what it means"*, never *"the wiring works"*. Does a retired pier
 really lose its route? Does the Door really hide it? Do the bytes really land? Those are Book claims and
  they remain owed.

**Regression swept over the WHOLE unit shelf** (31 specs, 217 assertions): **208 pass, 9 fail, and all 9
 are PRE-EXISTING** — proven, not assumed, by restoring the five generated ghosts to HEAD, re-running, and
  getting the identical nine, then restoring (byte-compared) . They are:
- `MultiHeist` ×3 and `HaulFace` ×4 — every one is `w.c.focused` reading `undefined`. `Sounditron.g:1161`
   still writes it, so this is the **`%Focus` migration** (`Statemap_todo`: "%Focus landed 2026-09-01")
    half-arrived: the specs still assert the `.c` flag the migration was moving off. Fix the specs to read
     the particle, or finish the migration — either way it is `Statemap_todo`'s debt, not this doc's.
- `Presence` ×1 — its own name says *"a real relay answers `who`"*. No relay is up; environment, not code.
- `LakeRace` ×1 — Lang/Lies dock handover, untouched by anything here.
⚠ Worth knowing for the next sweep: **the unit shelf is not green at HEAD**, so "9 failures" is the
 baseline, not a signal. Anyone running it cold will otherwise blame their own diff.

## 8. FLAWS AND WOBBLY BITS — gathered for the foundational fix (2026-09-07, with the owner)

> **Read `Fallen_out_of_mind_todo.md` beside this.** A twelve-reader sweep of the whole corpus (same day)
>  found that most of these "open" items were already RULED — some in the owner's words — then archived and
>   re-derived here without citation. Its §1 table maps each entry below to where it was decided.

The owner's charge: *"gather flaws so we can fix them all foundationally, and present a more
 un-screw-uppable world to the next app."* Each entry: the wobble · why it bites · the foundational
  direction. Written to be read by a human, not just re-derived by a session. Add to it.

**8.1 "Pier" means two things, and "soul" names a key as if it were a place.**
 · *(Corrected 2026-09-07 after the owner's "are you confused?" — the first draft described the
    pre-land-of-prepub seat model; the `_N` suffix code still exists but only as a collision fallback.)*
 · A friend's `%Pier` is keyed by **`page.prepub` — the prepub of the Body that sealed with them**
    (`Swarm_seal`: `peering.oai({Pier:1, pub: page.prepub})`). Under land-of-prepub every Body is its own
     address. So a Pier is *a Body we know*, and "Pier" is also read as *a role* (`reach.to:'Cave'`).
 · The **soul** is the Crew's *key* — `Swarm_soul`: "the crew's SOUL key {pub,key,prepub}"; the Captain
    *wields* it (holds the mutex), a Cave *carries* it. It is **never bound as an address** (grep: nothing
     routes `to:<soulpub>`). The owner is right that "soul" is non-descriptive: it is not who you call, it
      is what signs. → Rename in prose: **the Crew key** (wielded by the Captain, carried by Caves).
 · Fix: name the three things. **Body** (a device, its own address — what a `%Pier` actually points at),
    **Crew key** (what signs; never a door), **Post** (a role a Body plays: Captain, Cave). Retire the bare
     word "Pier" from prose; keep it as the mainkey only.

**8.2 Who does a foreign Crew call? — the Body it sealed with. Only that one, until taught otherwise.**
 · Measured: they address the prepub they sealed with. `Swarm_reach_addr` resolves `to` against **my own**
    roster only (`Swarm_body_for` → the Body playing that post); a foreign `to` is sent **raw**. A stranger
     cannot address a *post* in our Crew; they can only call a Body they already know.
 · Bites: the friendship is keyed to one Body. If that Body dies (an Incognito Cave that closed), the
    friend's frames go to a dead door — the Grink ghost, from the outside — and our other Bodies are
     reachable only if the roster (8.3) taught them. The owner: *"I think the Cave-services want to detect
      whether there is a Cave"* — presence of a *post*, not of a *door*, is the thing that should be asked.
 · Fix — **this wants a real design, not a patch** (the owner: *"design the way it wants to be a lot more,
    probably with all of these"*). The shape to design: a friendship keyed to a **Crew** (its key), with a
     *set of doors* (Bodies, post-tagged) learned from the roster, and a **natural state machine** per door
      (unknown → known → live → quiet → gone) so "is there a Cave?" is a query on state, not a guess from
       silence. Whether a protocol (Music, MyCave, Crew) resolves a post itself or the Crew resolves it is
        the open design question — answer it once, for all protocols.

**8.3 The slim roster is the intended model — today only a contact-learned cache travels.**
 · The owner: *"the bodies know the whole crew and give them (ongoingly) a slim roster of the Crew (without
    private keys!) — this is just some type of data our Piers want to give us, that unlocks further levels
     of communication with them... it's what everything's doing really."* Agreed — and that thing already
      has a name: the **Charter**, the signed export of `/Crew` (display + recovery, per Crew_todo). The flaw
       is only that the Charter does not yet travel *as the roster*: what a friend holds under our Pier is the
        contact-learned `%Body` cache (`Swarm_pier_of_body` prefix-matching inbound `from:`), partial and
         stale. The `crew-answers-not-the-roster` incident: this cache made a Cave scream theft at its own
          Captain.
 · Fix: the Charter *is* the slim roster; publish it to friends as data, ongoingly, post-tagged, and make it
    the only thing a friend consults about our Bodies. Same pattern as every other offer: data crosses,
     unlocks a level. Then 8.2's door-set is *given*, not inferred.

**8.4 The `Swarm_piers` accessor does not exist — and its proposed name is already taken.**
 · §2.1 proposes `Swarm_piers(ident,{live})`. It is **unbuilt**. Worse, the name is *already* a stash
    key (`st.Swarm_piers`, `Swarm_piers_rehydrate`) — exactly the collision §2.1's own caution predicted.
 · Fix: build it under a name that says membership, e.g. `Swarm_crew_of(ident,{live})` or
    `Swarm_souls(ident,{live})` (pairs with 8.1). Then the 126-site sweep.

**8.5 A husk is a `%Record` playing `%Card`'s part.** (the twin-record bug's root — §3.3, and the
 SoundPooling §0 autopsy)
 · A describe mints chunkless `%Record`s (`total:0`, `husk:1`) as its *catalog*. A materialise mints a
    full `%Record` under the **same** keep-id. Two shapes, one mainkey, one id — the exact tell
     CLAUDE.md records for the old magazine, recurring on the rummage path.
 · Fix: **a describe mints `%Card`; only a materialise/pull mints `%Record`.** Invariant: *a `%Record`
    always has bytes or a `total` that promises them; identity-without-bytes is always a `%Card`.*
     `total:0` + `%Record` becomes a contradiction the encoder can refuse. Then `Repli_find_record`
      cannot find a catalog twin, because catalog entries are not Records.

**8.6 The ask IS C-in-the-stream — but wrapped in imperative scaffolding the metaphysics never paid for.**
 · `Heist_rummage_ask` mints a `%Rummage` particle in a bay; `Repli_offer` replicates it; the source's
    beat *polls* its mirrors for landed asks and answers with more particles. Shared state, not RPC —
     the bet working. But: a **poll** not an event; a `≤3 answers / ≥5s` retry budget; an episode
      counter `ask.sc.n` — all there only because the wire drops frames and a value-upsert cannot tell
       "resent" from "new".
 · Fix direction: make *arrival* a first-class fact (a landed particle bumps a per-mirror `arrived`
    that the beat reads — event, not sweep), and make *episode* part of the particle's identity so a
     re-ask is a new particle rather than an in-place overwrite that needs a counter bolted on.

**8.7 The pool Books do not speak `%see` — so their progression is not readable as language.**
 · MusuHeist/MusuVend swear sentences (`see:'the pair sealed over the wire — …'`). The four pool
    Books record terse flag keys (`doer_served`, `cave_pressed`, `byte_faithful`) that accumulate
     step-over-step. The progression *is* there — MusuPoolFill goes `booked` → `+served,doer_served,
      cave_pressed…` → `+landed,pool_landed,byte_faithful,graduated` → `+refused,receipt_stands` — but
       a human reading the snap sees keys, not claims.
 · Fix: re-author the pool beats in `%see` sentences. The "arrayed armies of language" are only half
    arrayed while the app-side tests speak in tokens.

**8.8 This doc is written for a session, not a person.**
 · The owner: *"that doc is very for you."* True. §0–§4 are dense, code-pointing, and assume the
    reader re-derives. §8 is the first section written the other way.
 · Fix: keep §0 as the plain-language arc (destination · the bomb · the next move) and let the dense
    sections hang beneath it. A spec is *preened* by the owner; this is the todo that earns it.

**8.10 An Invite is a rendezvous, not a direction — the invitee must be able to pivot and invite back.**
 · The owner, 2026-09-07: *"if a Cave LinkDevices a Captain (with a MyCave) it becomes that the Captain is
    inviting the device to its Crew. Often it's easier to take the QR-code scan with a phone, which opens
     the app with that invite — then we use it only to find the other's address and kick off the ceremony
      anew. On the 'you got Invited' page we should be able to suddenly pivot to inviting them!"*
 · Today the QR fixes the direction at mint: the minter is the inviter, the scanner is the invitee, and a
    MyCave invite scanned by the wrong hand makes the wrong device the Cave. But the owner already named
     what a QR *is* — Swarm.g:944, 2026-08-09: an invite *"is essentially just saying 'come here', in a QR
      code"* — a **rendezvous**. Two facts got welded: *find me* (the address, which the QR carries) and
       *join me as X* (the role and direction, which should be decided once both are present).
 · Fix: split them in the social layer, where every Invite is exported to. A scanned Invite yields an
    **address + a warm door** and nothing else; the ceremony that follows is a fresh, mutual one in which
     *either* side may propose the direction (I join your Crew / you join mine / we become friends). The
      "you got Invited" page carries the pivot as a first-class verb. This also restores what Trust_todo
       flags Ferry lost: **mutual consent + SAS** — a rendezvous-then-propose shape is where that naturally
        lives. It belongs beneath the app: an app never knows which way a QR was pointing.
 · Pairs with 8.2 (a friendship keyed to a Crew with a set of doors) — a rendezvous is how a door is first
    learned — and with Swarm.g:7345 (*"a Cave produces another MyCave invite? I thought it would produce
     a MyCaptain"*): the invite's *kind* is a role question, answered at the pivot, not at the mint.

**8.9 (from §3.2, restated as a flaw)** Presence and membership are the same shape. A peer that is
 *gone* and one that is *quiet* both read as "a Pier with no fresh socket". → a presence **floor** for a
  granted, connected peer, and a terminal `dead` for a reach (§4.1) — so "gone" is a state, not a guess.
