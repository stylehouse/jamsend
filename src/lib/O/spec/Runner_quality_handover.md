# Runner_quality_handover — the "make it quality software" session (2026-07-02)

A continuation brief, not a changelog. The session's throughline: the runner machine felt broken —
 clicks getting lost, the editor death-spiralling — and we made it **snappy and honest**. The load-bearing
  knowledge is the *why* below; the diffs are all uncommitted in the working tree for the human.

Companions: `Cluster_runner_handover.md` (the networking half this extends), `Swarm_spec.md`
 (identity/social, formerly Swarm_doc — RENAMED), `Peeroleum_handover.md` (the spine — the
  packet-batching principle below was folded into its top).  `NeedAC_spec.md` was FINISHED and
   DELETED 2026-07-03 — the audio gate is built end-to-end (marker → dispatch-match → pre-run
    securing → Brink surfacing); its design tails live in the loose ends below.

---

## The destination we reached
The editor↔runner loop is **responsive** and clicks **land**. Two root fixes did it, plus a pile of honesty
 cleanups. Everything below is `.svelte`/`.g`/CLI — **owner-verify on the live :9091 editor+runner is owed**
  (reload both tabs; the spine change needs a full reload, and the relay change needs a dev-server restart).

## The bombs (knowledge that detonates if the next session lacks it)

1. **The belief queue was being flooded by every packet — this is THE perf lesson.** The real carrier
   (`Tribunal.g on_message`) wrapped EVERY inbound frame in `H.post_do` → `H.todo`, drained one-per-
    `ANSWER_CALLS_TICK_MS` (=50ms) under the beliefs mutex. At high frame rates (ping/pong, `control:log`
     per relay routing line, run_phase per step × N runners) that piled up — the editor hit **117 todos**,
      a ~6s backlog, a death-spiral. **Fixed three ways** (see the Peeroleum principle):
   - `relay.ts`: `control:log` now goes to **editor-bound sockets only** (`sendControlTo('editor', …)`), not
      every browser — runner tabs stop drowning. (Needs a **dev-server restart** to take effect.)
   - `Tribunal.g on_message`: **control frames handled INLINE** (console, never the queue); envelope/binary
      frames → `Lies_deliver_soon`. This is a **PINNED-SPINE change** — recompiled via LocalGen, re-pinned to
       `src/lib/p2p/pinned_stable/Tribunal.go`. (ghost-compile was wedged *because* of the spiral; use
        ghost-compile FIRST once the editor breathes — it now does; LocalGen is the fallback.)
   - `LiesLies Lies_deliver_soon`: **coalesces** — append to a per-w batch, and if a drain isn't already
      queued, ONE `post_do` drains the WHOLE batch in a single Atime pass (reusing `Peeroleum_deliver`, in
       arrival order). N frames → 1 drain slot. **Atime is kept.** NB it's a coalesced `post_do`, not the
        first-class `req:handle_inbound`/reqyoncile form the owner sketched — I chose post_do for zero
         req-machinery risk under the spiral; the reqyoncile form is the tidy follow-up (noted in the code).

2. **Clicks were getting lost because a new become_book `Story_reset`s the runner mid-run.** A burst of
   clicks (or the editor's own retries) to one runner *starved each other* — only the last survived (socklog
    caught 8 become_books → 2 run_results). **Fix:** on a single interactive click when all runners are busy,
     don't HOLD — **preempt** the runner you already drove (`Lies_preempt_target` → the sticky
      `aim_runner`/`rungo_runner`) via `Lies_send_become_book`; its Story_reset cancels the prior run. A click
       means "run THIS now." StoryTimes (the multi-run sweep) keeps its hold/parallel-acquire path. **Owner
        confirmed: "so much snappier!"**

3. **`Lies_secure_audio` opens the run record only AFTER AC is granted** — so for needAC, "the run record
   appeared" IS the grant signal. The CLI (`runner_ask`) now leans on exactly that (bomb #4).

## What else landed (honesty + cleanups)
- **`%friendly` KILLED** — gone from the data model (Clustation mint/concrete/adopt/self, Lies_self,
   advertise send/recv, roster + registry claim) and the UI. The Rundar rack shows the **prepub CSS-truncated
    to ~6ch** (`.rp-pub`, full pub on hover) — the pub IS the name; the `id-<6hex>` default was dead weight.
     `runner_ask` friendly bits removed too. Old `friendly` in Dexie / `wormhole/Cluster/toc.snap` is dead
      data (ignored, ages out).
- **needAC via CLI (self-narrating run, editor-side untouched)** — `runner_ask run` reads Credence
   (`bookNeedsAC` → `wormhole/Credence/toc.snap`) and passes `needAC` so the runner secures AC pre-run EVEN
    IF you never read Credence; `--watch` narrates `🎤 needs AudioContext` → `⏳ WAITING FOR permission` →
     `✓ granted — running` / `⚠ blocked (untried)` at ~60s (fail-fast, not the 120s hang). `probe` stays as
      the explicit fleet capability check — NOT a wasteful pre-flight for a run (owner's call).
- **EncodingSplatter "empty snap"** — a present-but-blank backing file fell through to `deWaft('')`. Guarded
   in `Lies.svelte LiesPersist` + `LiesStore_read_waft` (blank reads as not_found / start-empty, like the
    Library loader). Real corrupt files still surface.
- **`Clustation_self(w)` arg bug** — every caller passed `w` where the method wants the House (or no arg),
   so it returned `undefined` everywhere (incl. inside `Lies_self`). Fixed at 5 sites (call with no arg).
- **socklog** — the toggle/dump gate now agrees with the capture arm (`sockcap_count()`, not a URL check);
   armed via `?socklog`/`?watch`/the 🪪 toggle; swept the dumps; it's OFF. Kept as almost-GONER diagnostics.
- **gen-cluster-identos.ts DELETED** — editor self-provisions (🪪 Set up cluster trust); refs cleaned.
- **Swarm_spec.md** (the p2p social side) written + cross-linked into the Cluster/Radio/Swarm triad.

---

## Loose ends (be honest)
- **remoteWormhole: live end-to-end tested manually (2026-07-03).** The `%Grant`/`Lies_grant_wormhole`/
   `Lies_grant_offer_recv` machinery in LiesFunk, `&remoteWormhole=1` (was `&disk=proxy`), `RemoteWormholeNav`, binary replies via
    `Lies_send_binary_to` — all built and live-probed. The headless spec (`scripts/RemoteWormhole.spec.ts`)
     was deleted (wrong form — must be a Story Book). Binary-only: the `buf_to_b64` / `bytes_b64` fallback
      path was also removed (grant.for is always set; the degenerate `!to` branch was dead). Formal test
       is still owed as a Story Book (two-peer Pere* pattern).
- **needAC dispatch-match — BUILT 2026-07-03 (:9091-verify owed).** Advertise-then-match:
   the runner's beacon carries `ac:1` when its AudioContext is gesture-unlocked
    (probing the shared `top_House().c.musu_gat` cache), the roster folds it to a snapped `%Runner,ac`
     facet (Rundar tooltips show "AC live"), and `Lies_dispatch_target(w, needAC)` prefers an ac-live
      runner above every favour tier — prefer, never require (a fresh no-AC fleet must still get the beg).
       Held/swept runs re-read the board via `Lies_book_needac` since their queues carry bare names.
- **needAC design tails (folded from the deleted `NeedAC_spec.md`).** (a) **%rungo routing** — the
   eventual run-authority that waits for the exact compiled dige before firing, so a verdict provably
    matches the pushed source; staged BY DESIGN (~mid-Jul 2026, needs fleet coordination); the two
     begin-paths are cross-noted in-source at `Lies_become_book_drive` / `req_rungo`, and
      `Lies_secure_audio` is identical either way so the staging wastes nothing. (b) **Lapse policy**
       — a 60s `audio_blocked` lapse currently just reports blocked/UNTRIED; retry/park/drop on the
        editor board is undecided. The UNTRIED semantics are the load-bearing part: `!ok` + error +
         *nothing tried* — it must read "couldn't run here" (⌛/grey), NEVER "the audio delivery is
          broken", so a no-AC runner doesn't smear a needAC Book red. (c) **`^^What/RunnerAdvice`**
           — promoting the flat `%Storying,needAC` marker to a heritable What-limb advice; deferred.
            (d) **Cross-tab focus** — Brink-complain + runner self-signal (title flash / favicon /
             `setAppBadge`); true click-to-focus of an independently-launched tab needs a service
              worker + Notification; only editor-OPENED tabs can be `target`-focused.
- **Per-runner run_phase attribution (`from:<pub>` demux) — flagged ~4×, still not done.** `w.c.run_phase` is
   a single slot → the editor Brink can say "*a* runner needs AC" but not *which* tab. Cleans up run_phase
    clobber generally; a nice-to-have rather than a gate.
- **The `req:handle_inbound`/reqyoncile form** of the batcher (bomb #1) — the first-class version; I shipped
   coalesced-post_do. Owner sketched "out-of-time types" — worth building once things are calm.
- **Carried from earlier:** one-sided-ping dedup (Gardening pattern), `Book:PereBinary` (owed live-runner
   fixtures for the app-level binary content-dige; relay-level round-trip already proven in `relay-test.ts`).

## Next moves (in order)
1. **Owner: verify remoteWormhole on :9091** — `&remoteWormhole=1` runner + a granted read, watched from the Brink.
2. ~~needAC dispatch-match~~ **BUILT 2026-07-03** (see loose ends above) — verify by running MusuTune against
   a two-runner fleet where only one tab has granted AC: the ▶ should land on that one.
3. **The `from:<pub>` run_phase demux** — per-runner Brink attribution; nice-to-have.
