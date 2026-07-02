# Runner_quality_handover — the "make it quality software" session (2026-07-02)

A continuation brief, not a changelog. The session's throughline: the runner machine felt broken —
 clicks getting lost, the editor death-spiralling — and we made it **snappy and honest**. The load-bearing
  knowledge is the *why* below; the diffs are all uncommitted in the working tree for the human.

Companions: `Cluster_runner_handover.md` (the networking half this extends), `NeedAC_spec.md` (the audio
 gate, cross-agent), `Swarm_spec.md` (identity/social, formerly Swarm_doc — RENAMED), `Peeroleum_handover.md`
  (the spine — the packet-batching principle below was folded into its top).

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
- **remoteWormhole backending: headless spine now PROVEN (2026-07-02); live end-to-end still owed.** It was
   BUILT ("remote Wormhole pt1" in git; the `%Grant`/`Lies_grant_wormhole`/`Lies_grant_offer_recv` machinery
    in LiesFunk, `&disk=proxy`, `RemoteWormholeNav.frame_bytes`, addressed binary reply per `Cluster_spec §3.8`)
     with **no evidence any of it had ever run**. `scripts/RemoteWormhole.spec.ts` (the SendTo/relay-test
      trusted-headless family — direct method calls, NEVER the Story belief loop, so clear of the false-green
       trap) now exercises the FIRST run of: the %Grant crypto (mint/verify/tamper/forge/revoke, particle
        swap-out↔in), the **app-level round-trip** — the REAL `Lies_wormhole_req_recv` serving a REAL
         `RemoteWormholeNav` over an in-process loopback (read/list/**bin**/**read_range**/write + the ro-mode
          gate + forged-grant + wrong-editor rejects, against a fake full-contract nav — NodeWormholeNav can't
           stand in, it predates the binary verbs), and the runner lifecycle (`Lies_grant_offer_recv` verify→
            persist(.stashed + Waft:Cluster)→install, `Lies_wormhole_grant` read-back, idempotent install,
             broadcast filter + bad-sig drop). What the harness STUBS is the relay transport only — proven
              separately by SendTo (pub routing) + relay-test (buffer-intact binary frame). **Still owed, live
               :9091 only:** the real `&disk=proxy` boot quiescing to a granted nav, the real relay carrying the
                addressed binary reply between two tabs, and the editor Brink watch. First live probe unchanged:
                 a `&disk=proxy` runner reading one file through the granted nav, watched from the editor Brink.
- **needAC dispatch-match NOT done** — `Lies_dispatch_target` ignores needAC, so a needAC Book can still land
   on a no-AC runner → 60s block. Needs the **audio-capability advertising** (Radio agent / Swarm §4: the
    runner advertises `audio`/`provides_audio`) + a `needAC ⇒ prefer audio runner` filter. Coupled — sequence
     the advertising first.
- **Per-runner run_phase attribution (`from:<pub>` demux) — flagged ~4×, still not done.** `w.c.run_phase` is
   a single slot → the editor Brink can say "*a* runner needs AC" but not *which* tab. NeedAC's §6.4 is the
    concrete reason to finally land it; it also cleans up the run_phase clobber generally.
- **The `req:handle_inbound`/reqyoncile form** of the batcher (bomb #1) — the first-class version; I shipped
   coalesced-post_do. Owner sketched "out-of-time types" — worth building once things are calm.
- **Carried from earlier:** one-sided-ping dedup (Gardening pattern), `Book:PereBinary` (owed live-runner
   fixtures for the app-level binary content-dige; relay-level round-trip already proven in `relay-test.ts`).

## Next moves (in order)
1. **Owner: verify on :9091** — restart the dev server (relay + spine + LiesLies), reload editor+runner. Watch
   H.todo stay low; clicks land; `↻ preempting` on a busy click; the needAC narration on a needAC Book run.
2. **Test remoteWormhole** — headless spine now GREEN (`scripts/RemoteWormhole.spec.ts`); what remains is the
   LIVE end-to-end: a `&disk=proxy` runner + a granted read, watched from the Brink (real boot + real relay).
3. **Audio-capability advertising → needAC dispatch-match** (with the Radio agent).
4. **The `from:<pub>` run_phase demux** — unblocks per-runner Brink (incl. "which runner needs AC").
