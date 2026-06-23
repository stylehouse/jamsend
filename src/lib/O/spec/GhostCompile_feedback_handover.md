# ghost-compile / channel feedback — handover

A continuation brief for the next agent. Arc, bombs, next move — not a changelog.
Pairs with `Editron.md` §3 (the request half is done there; this is the verdict-reply work).

## Destination

Make `ghost-compile` and the editor↔runner channel **tell the truth about delivery**.
The original sin: the CLI sent a frame, closed the socket, and `exit 0`'d — reporting a
success it never confirmed. A dead/half-open editor should be **legible** (the CLI says
why; the runner *shows* it), not a silent `0 confirmed` mystery.

## Landed (working tree, uncommitted, verified live)

- **Phase 1 — CLI lifecycle** (`scripts/ghost_compile.ts`, rewritten). Sends with a `corr`
  id, **stays open**, narrates to stderr, settles each ticket on the FIRST of: served-`.go`
  dige-flip (ground truth, HTTP-polled) · relay `undeliverable` · editor `ghost_compile_ack`
  · **timeout (12s)**. Verified both ways: `✓ compiled @ dige` (editor up) and
  `✗ no response in 12s (editor half-open?)` (editor gone). Backward-compatible — the
  dige-flip poll carries it with zero editor changes.
- **In-UI runner log.** `Ghost/N/Tribunal.g`'s new `note()` rings the relay `control:log` +
  carrier SEND/RECV/OPEN/CLOSE/reconnect/ERROR onto `w.c.relay_log` (off-snap, capped, **no
  version bump**). `src/lib/O/Funk/Relay.svelte` renders them as fade-out toasts on its 1s
  tick (routine 5s, `important` 60s). Compiled + promoted to `p2p/pinned_staging/Tribunal.go`.

## Bombs (lose these and you'll re-derive them the hard way)

1. **`deliverLocal` is half-open-blind** (`relay.ts:112-121`): returns `true` for any
   `readyState===OPEN` socket — a TCP-half-open zombie still reports OPEN, so the relay
   "delivers" into the void and never logs `DROPPED`. **This is the actual failure mode**
   (the runner Lens flapping live/silent/dialing is its signature). So `undeliverable`-on-
   clean-absence is *insufficient alone* — `locals` needs the heartbeat-pruning the **bridge
   leg already has** (`relay.ts:144`, "non-OPEN is down"); copy that pattern.
2. **The timeout is load-bearing**, not a fallback — the only thing that catches the half-open
   case where neither `undeliverable` nor an ack ever arrives.
3. **No standalone compiler exists** — `ghost-compile` is relay→**live editor** only
   (`lang-compile`/`compile_core`/`compile_request` deleted). You **cannot headless-verify**
   a `.g`; the `Tribunal.g note()` edit is plain raw-JS but unconfirmed until an editor compiles it.
4. **Editor rides the FROZEN `pinned_staging` spine** — `.g` edits reach the *runner* via
   `ghost-compile`; the *editor* only after `cp gen/N → pinned_staging` (done for Tribunal).
5. **Never bump `w.version` per frame** — the ring deliberately doesn't (the `run_phase`
   re-pump wedge); it's poll-on-tick.
6. **CLI isn't a relay peer** (no addr). `#1 undeliverable` needs no routing (reply on the
   receiving socket). `#2 ack` does — map `corr`→sender-socket in the relay, or add a `listen`
   ephemeral-addr bind. The CLI already sends `corr` and listens for both.

## Next moves — #1, #1-real, #2 ALL LANDED (uncommitted, typecheck-clean, browser-UNVERIFIED)

1. **`#1` relay `undeliverable` — DONE.** `routeFromBrowser` returns `'local'|'bridge'|'dropped'`;
   the browser-message handler replies `{control:'undeliverable', to, path, corr}` on the asking
   socket when a `ghost_compile` (carrying `corr`) drops. The CLI settles `no-editor` at once.
2. **`#1-real` half-open prune — DONE.** A WS-level ping/pong heartbeat (`relay.ts`, 15s): each
   socket carries `isAlive`, re-proven on `pong`; a missed round → `ws.terminate()` → its close
   handler unbinds it from `locals`, so `deliverLocal` (still `readyState===OPEN`-based) no longer
   lies — the dead socket is gone before it's consulted. Plus `relay.ts` now logs
   `browser DISCONNECTED addr=… code=…` (was silent — the "two binds, no close" mystery).
3. **`#2` editor `ghost_compile_ack {started|done(dige)|error(errors)}` — DONE.** `started` in
   `Lies_ghost_compile_recv` (+ stashes `corr` keyed by path on off-snap `w.c.gc_acks`); `done` from
   `Lang_drain_compile_settles` when `Lies_compile_settled` fires; `error` swept there too (a dock
   that stamped `compile_error`). All via `Lies_ghost_compile_ack` — a raw `control` frame down the
   editor's socket (NOT a Peeroleum envelope; the CLI is no peer), corr-routed back by the relay's
   `ackBack` map (CLI has no addr). `error{errors}` is the debug signal a dige-poll can never give.
4. **Adjacent fixes that unblocked this** (LiesLies/heartbeat — see [[ghost-compile]], spec/Lens):
   the liveness watchdog was force-closing the socket *mid-compile* on a stale-`last` reading
   (self-perpetuating flap); now it measures silence by `max(last, last_heard)`. And `last_heard`
   (stamped on any inbound frame in `Lies_pong`) makes the Runner Brink read live off inbound traffic.

## Still open

- **Browser-verify the whole loop** on a live editor/runner pair: `ghost-compile` → `✓ compiled @ dige`
  (or `✗ … compile error — <msg>`); the Relay Brink lights `🔄 compiling…` (bold, sticky 60s) and a
  half-open editor logs `✂ half-open socket terminated`. The `relay.ts` changes need a **server restart**
  (server code, not HMR); the LiesLies/LangCompiling changes HMR live.
- **`note()` still doesn't stamp `important`** (the carrier's own CLOSE/reconnect/OPEN in `Tribunal.g`
  fade at 5s; my consumer-side reconnect-reason + compile-landing are `important`/60s). Wiring it needs
  a `Tribunal.g` recompile + `cp gen/N → pinned_staging` (the frozen spine) — deferred.

## Niggles

- **`note()` never stamps `important`.** `Relay.svelte`'s log now persists `important` events
  60s (vs 5s routine), but `Tribunal.g`'s `note(line, warn)` only pushes `{line, at}`. Wire an
  `important` flag for reconnect / CLOSE / a compile landing so they don't fade in a blink.
- **Host commit `6c13b6a1`** ("UIless compiling is a service, Funkcion Lens") folded my
  `compile.ts` de-junk in and **reworked the Lens system** (`Runner.svelte` +111, new
  `LensHost.svelte`). `Relay.svelte` is confirmed compatible (`LensHost.svelte:23` passes
  `lens`+`funk`); my pre-rework "dialing" line-cites in older notes are stale.
- CLI narration is on **stderr** (keeps `--json` clean on stdout) — flip if strict stdout is wanted.
- `pinned_staging/Peeroleum.go` left stale (cosmetic `figaro` test-word delta only).

## Working tree
`scripts/ghost_compile.ts` · `Ghost/N/Tribunal.g` · `src/lib/O/Funk/Relay.svelte` ·
`src/lib/p2p/pinned_staging/Tribunal.go`
