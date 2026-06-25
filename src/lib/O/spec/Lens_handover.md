# Lens + Aim — handover

The ambient hoisted-UI layer (the **Lens**) and where it's heading (the **Aim** layer —
 "another Lies, but for endpoints").  Written at a resting point; the Lens seam is built and
  typechecks clean, the Aim layer is designed-not-built, and there is one confirmed reactivity
   bomb to defuse first.

## Destination

A second presence surface beside the InterestStrip: the **Lens**, a bottom-accreting stack of
 floating panels that Funkcions (or system pokes) hoist over Lies.  Its payoff tenant is the
  **Aim layer** — a `Waft` whose particles are *endpoints* (editor / runners / relays) the way
   Lies's particles are *docks*, with a Funkcion family that monitors liveness, logs server
    events, routes runs, and persists intent (`%Aim`).  The Runner panel is that family's first
     member.  In parallel, **CreduFunk** is meant to become a *viewer* of the per-Story
      Credulate snaps (Editron.md §7), not the second journaler it still is.

## What's built (the arc)

**The Lens seam — plural by design.**  A Lens particle is `Lens:<LensKind>,of_Funkcion:<kind>`:
- the **Lens-KIND** (mainkey value) is the slot|intensity — `Panel` rides the bottom dock,
  `InterestSmall|InterestBig` are reserved to pop in the InterestStrip;
- **`of_Funkcion`** names the source Funkcion;
- the Funkcion offers a face per slot: `FunkKind.comp_<LensKind>` (kinds.ts).  `component` stays
  the inline in-Waft face (FunkHost); the new `comp_*` are the hoisted faces (LensHost).

Pieces:
- `O/Funk/kinds.ts` — `FunkKind` gained `comp_Panel? / comp_InterestSmall? / comp_InterestBig?`.
- `O/Funk/LensHost.svelte` — the floating sibling of FunkHost: mounts `FUNK_KINDS[of_Funkcion]['comp_'+LensKind]`.
- `O/ui/Lens.svelte` — the dock: `position:fixed; bottom:0; column-reverse`, ordered by `altitude`
  (z = altitude×100).  Reads the held Lenses off **`top_House().ave.{Lenses:1}`** (off-snap, never
   pumped: no `c.up` in the A/w spine, ave is outside the snap tree).  Mounted once in `Otro.svelte`.
- `O/LiesWaft.svelte` — `Lies_lens_bag()/suggest(lensKind, of_Funkcion, sc, funk?)/dismiss/toggle`.
  Identity is `(LensKind, of_Funkcion)`; re-suggesting is an oai-merge + bump = the change-notice.

**Tenant 1 — IdHatch** (`comp_Panel`, `altitude:88`, fullscreen via its own FaceSucker).  The
 `Id` action (`Auto.svelte`) now `Lies_lens_toggle('Panel','IdHatch',{altitude:88})`; the old
  `H.stashed.showId` flag + the hardcoded Otro mount are **retired**.  Looks identical to before
   (that was the proof).

**Tenant 2 — Runner** (`O/Funk/Runner.svelte`, `comp_Panel`, `altitude:20`).  The endpoint monitor:
 four honest liveness states (`✕ no channel → ◌ dialing → ◍ silent Ns → ● peer 414ms`, plus `⚠ clash`)
  + the in-flight `run_phase` blip.  It reuses the existing machinery — `%channel_peer{rtt,last}`
   (stamped by `Lies_pong_recv`), `Lies_channel_live`, `w.c.run_phase`.  Suggested from
    **`Lies_heartbeat`** (`LiesLies.svelte`) whenever the role is editor|runner, dropped when the
     role lapses, parameterized by **`lens.c.w`** *on purpose* so the Aim layer can point N Runners
      at N endpoints.

All edited regions typecheck clean (the residual `Lies_channel_live`/eatfunc "not on type House"
 lines are the documented baseline noise — CLAUDE.md).  **Nothing is browser-verified.**

## The bombs

1. **Runner reactivity (confirmed by the user — defuse FIRST).**  The panel's `now` only updates
   when `w:Lies.version` bumps.  After a run is dispatched and the channel goes idle, *nothing
    bumps w*, so the liveness age, the silent-countdown, and the planned flashing-orange freeze.
     FIX: a local `setInterval` bumping a `now` `$state` (~1s) with `onDestroy` cleanup, independent
      of w — in `Runner.svelte` and any future Aim panel.  (Liesui dodges this via an ambient 3s
       heartbeat bump; a hoisted panel can't rely on that being live.)

2. **Reconnection gap (Peeroleum-side, NOT an O/* fix).**  After a run, neither end re-dials the
   other; liveness just decays.  The only existing partial is `Lies_heartbeat`'s >20s force-reconnect
    watchdog.  Real fix is transport-spine work — see bomb 3.

3. **`pinned_stable/` is the frozen spine — reliability work lands THERE, not in O/*.**  The host
   renamed `p2p/transport/` → **`p2p/pinned_stable/`** (`Peeroleum.go`, `Tribunal.go`) this session.
    The editor compiles the spine but imports these *frozen* copies so editing it doesn't HMR its own
     channel (Editron.md §3; promote with `cp gen/N/*.go → pinned_stable/`).  Anything that becomes
      transport behaviour — new ping/reconnect frames, server-down probing that rides the spine —
       eventually ships as `pinned_stable/Peero*.go`.  **Prototype monitoring/UI in `O/*`** (where all
        the Lens/Runner/Aim work lives — plain ghost modules, live HMR); only graduate to the spine
         when the editor must run it without HMR-reloading the channel.

4. **Runner double-shows** with Liesui's inline `.ls-runphase`/badge on the editor.  Liesui left
   untouched to avoid a risky extraction; retire its inline copy once the Lens version is eyeballed.

5. **CreduFunk is still the duplicate journaler** (`credufunk_run` stamps `CreduCoherence`).  Retire
   it → make it a viewer of `wormhole/Story/<Book>/Credulate/toc.snap`.  The `Credulation →
    CredulateHistory` rename ("a credential that accretes") is decided but **unbuilt** — the per-Story
     `Credulate/` + `Credulation/` dirs are now being written (untracked), still old-named.  (Editron.md §7.)

## The next move — %Aim

`%Aim` **manifests as a Waft** (Waft:Aim / the Cluster doc) that embeds Funkcions which poke
 `comp_Panel`s into the Lens dock.  Slices, in order:

1. **Defuse bomb 1** (Runner local ticker).
2. **`Aim` Funkcion kind, `comp_Panel` = the overall traffic light**: **green** (going well) /
   **red** (failing) / **orange** (in progress) / **flashing orange** (still going).  Aggregate the
    signals we already have: endpoint liveness (`Lies_channel_live` = server/relay up vs
     `%channel_peer` stale = peer down — *two distinct signals*), `run_phase` in-flight, and
      `%run_result` verdicts.  Suggest it at an altitude above Runner so it caps the stack.
3. **%Aim defaults to a server-watch / log Funkcion.**  The sources already exist:
   - **server log lines** — `relay.ts` `relayLog` (line ~86) already pushes every relay log down each
     local browser socket as a **`{control:'log', line}`** frame.  These are *control* frames, not
      Peeroleum consumer frames, so they need a surface handler — wire one and ring-buffer them.
   - **ghost-compile events** — already a Peeroleum frame: `Peeroleum_on(w,'ghost_compile',…)` →
     `Lies_ghost_compile_recv` (`LiesLies.svelte:217`).
   - **server-down** — `!Lies_channel_live(w)` is the relay/socket-down signal (distinct from a stale
     peer).
4. **Make it a real navigable Waft** (toc.snap fixture + embedded `Funkcion:Aim` / `Funkcion:Runner`),
   so the Aim doc is editable like any Waft and one Runner rides per endpoint.

Then the slower threads: the **excitement/awakeness scheme** (run_when floor + Interest-cursor excite
 level → lens-kind intensity + an MRU budget on the awake set — designed, unbuilt) and the
  **InterestStrip pop-outs** (`Lens:InterestSmall|Big` off the same bag — small).

## Map of the family (the mental model)

| Lies (doc layer) | the Aim layer (endpoint layer) |
| --- | --- |
| subject = Wafts/docks on one origin | subject = endpoints (editor / runners / relays) |
| `%run_result` per dock | liveness + each endpoint's current run |
| Funkcions: Storying, StoryTimes, CreduFunk | Funkcions: **Runner** (monitor/endpoint), **ClusterRun** (router), **Aim** (intent) |
| verdict wire (rungo / run_result) | orchestration wire (become_book / ping / `control:log`) |
| Credence reads verdicts back | the Aim-station reads endpoint state + intent back |

Lies orchestrates docks within one origin; the Aim layer orchestrates origins.  Both hoist their
 faces through the one Lens dock.  Cross-refs: `Editron.md` (§3 freeze, §4 Funkcions, §7 CreduFunk),
  `Waft_spec.md` (Funkcions, presence model), `Peeroleum_handover.md` (the transport spine).
