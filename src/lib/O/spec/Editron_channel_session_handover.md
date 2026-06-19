# Editor↔runner channel — session handover (the wire still isn't carrying)

Destination, the bombs, the next move. Companion to `Editron_runner_channel.md` (the ask)
 and `Peeroleum_spec.md`/`Peeroleum_handover.md` (the spine). Read those first; this is the
  "what a session burned and what it learned" layer on top.

## Destination

Editor (`Lies%editor`, Editron Book) edits a `.g`; runner (`Lies%runner`) re-lands the source,
 recompiles, mounts, **runs**, reports back — across two origins, over Peeroleum's real websocket
  transport (heading 10), relay on each origin's node server bridged server-to-server. The
   consumer half (registration, send, the dock_push/run_result handlers) is built. The session's
    whole fight was getting a single app *envelope* to actually cross.

## The arc this session

Started on a `💭 !method: e_Lies_compile_settled` log, ended still unable to cross an envelope.
 In between, peeled the onion one layer at a time — each layer looked like the answer and wasn't:

1. **Compile-settle drain** — `Lies_compile_settled` was stranded (its `o_elvis` drain sat behind
    an active-dock guard, so the declaration stamp was never written headless). Fixed: an
     unconditional `Lang_drain_compile_settles` parks a one-shot `req:compiled_is_settled` that
      clears `Compile.pending` by the settle's own `path`. (`LangCompiling.svelte`, `Lang.svelte`.)
2. **The {control:role} crash** — the relay's `{control:'role'}` reply (no `header`) was reaching
    `Peeroleum_deliver`, which did `frame.header.type` → TypeError. Fixed: `Socket_real.onmessage`
     routes `control` frames aside before deliver. (`Tribunal.g`.)
3. **Transport ghosts never loaded** — `Socket_real` etc. were only included by the Peregrination
    *test*; the real app never compiled+included them, so `Lies_channel_up` silently returned at
     `typeof Socket_real !== 'function'`. Fixed: `Lies_transport_up` includes `gen/N/Peeroleum.go`
      + `gen/N/Tribunal.go` directly (enrol as `UI:Pantheate-include` → Otro mounts → eatfunc
       deposits). (`LiesLies.svelte`, `Lies.svelte`.)
4. **The send-gate was dead** — both send sites gated on `Peeroleum_peer_ready` =
    `req:handshake.finished`, but `Lies_channel_up` stamps `Ud` directly and seeds no handshake, so
     it was never true. Swapped to `Lies_channel_live` (channel up + carrier wired), matching the
      consumer's deliberate trust-everything v1. (`LiesLies.svelte`.)
5. **The keystone** — `Tribunal_activate_websocket` did `w.o({active_transport:1})[0]` and bailed
    `if(!at)`. Nothing in the real channel ever *creates* `active_transport` (only the mock
     wrangler does, as its step 2). So `active_transport.c.connection` was never set →
      `Peeroleum_send` dropped **every** envelope. Fixed: `oai` not `o`. (`Tribunal.g`.)
6. **Ping/pong + badge** — a 3s heartbeat; the peer echoes a pong; `Lies_pong_recv` stamps
    `%channel_peer{role,rtt,last}`; Liesui shows `● runner 12ms` / `○ runner` beside the role
     badge. The `○→●` flip is the only honest, human-visible proof the envelope path carries.
      (`LiesLies.svelte`, `Lies.svelte`, `Liesui.svelte`.)
7. Tidied the `req_legs ✓ N` per-beat spam (kept the mismatch warn; `V.req_legs` drives the walk,
    left on). Swapped the `⚡` wire logs to `🛰` (more visible). (`Housing.svelte.ts`, the `.g`s.)

## BREAKTHROUGH (end of session) — the envelope crosses

After the `active_transport` `oai` fix went live and the bridge port was sorted, real app frames
 finally crossed: `🛰 Peeroleum_send dock_push … (transport live)` + `🛰 ws SEND dock_push → runner`.
  The transport is proven. What's left is payload + run semantics, not plumbing.

**dock_push is now version-only, not source.** Decided + implemented this session: both origins
 share the disk and Vite HMR already delivers the recompiled `.go` to the runner, so shipping the
  18KB `.g` source over the wire is pointless. `dock_push` now carries `{ path, ghost_version }`
   (the `source_dige` the editor's Ghostmeta bakes in). The runner ACQUIRES that version locally
    (HMR re-runs the module's eatfunc → `Ghostmeta_<name>()` reports the live dige):
  - live dige == wanted ⇒ run it (invalidate the Good + `i_elvisto(w,'think')` drives recompile|re-run);
  - live dige != wanted ⇒ reply `run_result{ok:false, errors:['failed to acquire src …']}` (editor red).
  ⛑ **Race to fix:** HMR can lag the frame, so an immediate miss false-errors. The runner side
   needs a **ttlilt poll** — on miss, trigger the acquire (re-read + think) and wait a beat for the
    revision before erroring. `Lies_dock_push_recv` is written as the immediate check with this
     flagged; turning it into a poll-then-error is the obvious next edit. (`Editron_runner_channel.md`
      §"frame types" still documents the old `{path,source,dige}` body — update it.)

## The bombs — knowledge that, missing, dooms the next session

- **A connected socket proves NOTHING about envelopes.** `become`/`role` are sent straight down
   `ws.send` and bypass `active_transport` entirely. So "ws OPEN + role confirmed" can be fully
    green while every real frame hits the floor. This single confusion ate most of the session.
    The ping (`🛰 channel VERIFIED`, badge `●`) is the antidote — trust *that*, not the socket.
- **`active_transport` must exist or `Peeroleum_send` drops silently** (logs `transport MISSING`).
   Fixed in `Tribunal.g` — but it's a `.g`: it only takes effect once `gen/N/Tribunal.go` is
    **regenerated** (open/recompile it in the editor) AND both tabs hard-reloaded (`channel_up`
     guards `if(w.c.channel_up) return`, so a stale House won't re-run `activate`). Verify by the
      snap growing `+ active_transport,type:websocket` under `w:Lies`. As of last snap it was STILL
       ABSENT — i.e. the keystone fix was not yet live. **Start here.**
- **The r2r bridge likely dials the wrong port.** `relay.ts:31` hardcodes
   `DEFAULT_EDITOR_RELAY = ws://localhost:9091/relay?r2r=1`, but the live setup has the **editor on
    :9092** and the **runner on :9091** (per the `ws OPEN …addr=editor` / `…addr=runner` logs). So
     the runner (:9091) dials :9091 — itself — and the bridge to the editor (:9092) never forms;
      cross-tab frames can't route. Set `EDITOR_RELAY=ws://localhost:9092/relay?r2r=1` on the runner
       server (or whichever origin is truly the editor) and confirm `RelayHandle.peerReady`. The
        spec (`Editron_runner_channel.md`) says editor :9092; `relay.ts` default says :9091 — they
         disagree; the runtime wins.
- **`.g` edits need the editor to recompile them.** `Lies_transport_up` imports the *checked-in*
   `.go`; editing `Tribunal.g`/`Peeroleum.g` does nothing until the editor compiles them (writes
    `gen/…`), then Vite HMR re-runs the module's `eatfunc`. `npm run lang-compile -- <f.g>` only
     *checks* (stdout), it does not write `gen/`.
- **`mode` never crosses.** The editor's `run_arm{mode}` is local-only; the runner re-runs
   *implicitly in_place* whenever a `dock_push` (source) lands. `dock_push` carries `{path,source,
    dige}` — no `mode`. So `from_start` from the editor does nothing to the runner. Wire it by
     adding `mode` to the `dock_push` body (and branching in `Lies_dock_push_recv`) or a dedicated
      `run` frame, once frames actually flow.

## Working-tree state (uncommitted — human commits)

Touched, all left in the tree: `LangCompiling.svelte`, `Lang.svelte`, `LiesLies.svelte`,
 `Lies.svelte`, `Liesui.svelte`, `Housing.svelte.ts`, `Ghost/N/Tribunal.g`, `Ghost/N/Peeroleum.g`.
  The `.g`s compile clean (`lang-compile ✓ PASS`); the `.svelte`s preprocess+compile clean (full
   `svelte-check` OOMs against the live dev server — use per-file `svelte/compiler` preprocess).
    `gen/N/*.go` are STALE w.r.t. the `.g` edits until the editor recompiles them.

## Next move (ordered)

DONE this session: bridge carries, `active_transport` live, dock_push is version-only.

1. **Make the version handshake robust** — turn `Lies_dock_push_recv`'s immediate Ghostmeta check
    into an **acquire-then-poll**: on miss, trigger the acquire (invalidate Good + think) and arm a
     ttlilt; run on match, `failed to acquire src` only on timeout. Without this every edit races
      HMR and may false-error. THE next edit.
2. **Confirm the run actually fires** on the runner when the version matches (does `delete
    good.c.content + think` re-run the Story step under `w%runner`? verify, or use the runner's own
     `e_Lies_run_arm` path). Then `run_result` should come home and light the editor badge/staging.
3. **Wire `mode`** onto `dock_push` (`{path, ghost_version, mode}`) + branch in the runner so the
    editor's `in_place`/`from_start` actually drives the runner (today `mode` is editor-local).
4. **Bridge-event broadcast** (the human-UI ask): in `relay.ts`, on `peerLink` open/close,
    broadcast `{control:'peer-relay', up:bool}` to all local browser sockets; the browser
     `onmessage` already routes `control` aside (the guard) — add a branch → stamp a particle →
      surface by the badge, alongside the ping `●`. This is the *server-server* state, distinct
       from the *peer-pong* (ping) state — the human wants both.
5. **Update `Editron_runner_channel.md`** §"frame types": `dock_push` body is now
    `{path, ghost_version}`, not `{path, source, dige}`.

## Open

- `Peeroleum_peer_ready` (real handshake) vs `Lies_channel_live` (v1 trust-everything): the spine's
   `alice/bob` mock handshake demonstrably works, so driving a *real* `req:handshake` on the Pier in
    `Lies_channel_up` is viable later — it'd light up `hello`/`trust` across the relay for real.
- The stuck-compile blob (`req:compile,firing` + `ttlilt,waiting:gen_write,timed_out` +
   `Compile,pending`) recurred live, not just headless — confirm the `req:compiled_is_settled` drain
    is actually clearing it in the editor; it's a side-show to the channel but it muddies the snap.
