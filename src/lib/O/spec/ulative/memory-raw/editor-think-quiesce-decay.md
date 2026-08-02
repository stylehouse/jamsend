---
name: editor-think-quiesce-decay
description: "idle editor's think-quiesce freezes the in-think Rundar roster → '● connected — no identity / ◍ channel live · beacons stale' + become_book held; interaction (a think) heals it; fix candidate = beacon-driven ungated think nudge in Lies_keepalive"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5208f8a1-b006-4307-96b3-31bdbb777ccb
---

2026-07-11 (night): diagnosed the editor's recurring "● anon connected — no identity /
◍ channel live · beacons stale" + "can't send become_book" (user: "it's just having trickle
think() Off. cluster is snappy again. maybe that shouldn't be necessary").

**Chain (all confirmed in code):**
1. Advertise beacons land OFF-think, parked on `w.c.beacons` (LiesLies `Lies_advertise_recv`) —
   deliberately no snap-tree mutation there.
2. ONLY the IN-THINK `Lies_runner_roster` (a Lies_aim do-pass) folds beacons into the snapped
   `%Runner` rows + Waft:Cluster registry. The route's `feebly_ponder` nudge is RUNTIME-GATED
   (no-op on an idle editor).
3. An IDLE editor think-quiesces → rows' `.c.last_heard` freeze → Rundar rack rows age silent →
   cull past OFFLINE_CULL_MS → `rack_shown` empty, while ping/pong liveness stamps ride off-think
   so `live_face` stays fresh → Rundar shows the anon row `● connected — no identity`
   (Rundar.svelte ~171) + `◍ channel live · beacons stale` (stale_hint, ~178). Its tooltip blames
   "a flapping socket" — WRONG for this mode; transport was perfect.
4. Dispatch reads the same frozen roster → "⏸ become_book held — runners known but none live yet"
   (LiesFunk ~1725). So "editor can't send Storyings" while pings flow.
5. ANY think (user interaction, a run) refolds → "cluster is snappy again".

**Observable from the container:** `wormhole/Cluster/toc.snap` mtime goes stale while beacons
flow = the editor isn't folding. runner_ask talks straight to runners, so CLI dispatch is NOT
blocked by this — only the editor's own dispatch/UI.

**Fix BUILT 2026-07-11 night (uncommitted, LiesLies.svelte):** the data-driven WAKE — stamp
`w.c.last_roster_fold` in Lies_runner_roster; in the 5s `Lies_keepalive` (survives think-quiesce
by design), editor-role only: any `w.c.beacons[*].last_heard > last_roster_fold` →
`i_elvisto(w,'think')` (ungated, self-quenching). PROVEN for idle-quiesce: 20 min pure idle,
max 24s between in-think beats (socklog dump cadence = the think observable).

**SECOND disease the nudge does NOT fix — the freeze→thaw WEDGE (2026-07-11 09:11):** a brief
browser/system freeze (~09:10) thawed with a queued-pong burst; the editor folded ONCE on thaw
(Cluster toc 09:11:03), dumped socklog once (09:11:14), then thinks STOPPED PERMANENTLY while
pings/pongs kept flowing at 6s cadence (event loop alive, no timer throttling). Beacons kept
arriving and the nudge kept queuing wakes — so the belief MUTEX (or the todo pump) is wedged on
a thaw-path await that never resolves (cf [[remotewormhole-mutex-deadlock]], o_elvis race; the
in-flight socklog rw_op's reply may have died mid-freeze). Signature triple: editor socklog
frozen + Cluster toc frozen + pings alive. Needs the tab console to root-cause — from the
container you can only watch for self-heal (watched 13 min: NONE). THIS is likely the user's
original "after a while" disease; idle-quiesce was the milder cousin. NOT editor-only after all: at 10:45 the same
wedge struck runner 49de (socklog dead, pings alive briefly, then full tab-freeze), while 3c52
sailed on — so it is ROLE-INDEPENDENT and PROBABILISTIC (wedges only when a think is mid-await
as the browser freezes the tab). Earlier same-morning: both runners survived the 09:10 freeze
that wedged the editor. Suspects narrow to paths BOTH roles run in-think (last completed think 09:11:14; suspects: an editor-only req chain — Editron/StoryTimes/gen
watch/a Wormhole rw whose reply died mid-freeze). A wedged tab is a LIVE SPECIMEN: root-cause in
DevTools BEFORE reloading (H.todo backlog of merged think elvises, the beliefs-mutex holder,
pending promises). The built nudge is adjacent-in-time but ran clean 45+ min incl. full run
cycles pre-freeze, and the disease predates it (evening badge + ghost-compile timeouts) — still,
its diff is one small LiesLies block, trivially revertable to test.

----
## merged from page-lifecycle-warmth.md

---
name: page-lifecycle-warmth
description: Runner warmth via Page Lifecycle freeze/resume + the load-bearing change that dispatch_target/preempt_target now GATE on r.sc.ready (a going-cold runner is heard but skipped)
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

Task #35 (BUILT 2026-07-05, :9091-browser-verify-owed — freeze/resume can't be CLI-triggered). Completes the audio-keepalive half ([[runner-quality-session]] / SoundSystem.keep_awake + the Auto runner gate). All in LiesLies.svelte, attached once per channel in Lies_channel_up beside the keepalive setInterval.

- **Lies_lifecycle_hook(w)** — guarded by `w.c.lifecycle_hooked`. On `resume` + `visibilitychange→visible`: clear last_ping/last_advertise + one `Lies_keepalive` pass (its watchdog re-dials if the sleep outran DEAD_MS since `now` jumps past it on wake, else it re-ping+re-advertises) + explicit `port.reconnect()` if the ws didn't survive. On `freeze`: `Lies_going_cold`.
- **Lies_going_cold(w)** — runner-only, SYNCHRONOUS (freeze is the last code before suspend): one raw `advertise{ready:0}` so the editor drops the grant THIS beat, ~45s before the LIVE_MS live-gate would.

**THE BOMB (why the freeze half isn't cosmetic):** `Lies_dispatch_target` + `Lies_preempt_target` historically picked on `live()` (last_heard fresh) + `busy()` — they did NOT read `ready`. A cold advertise refreshes last_heard, so a just-frozen runner would stay in the pool for the full 45s. So I made both pickers gate candidates on `r.sc.ready`. **Consequence a future dev must know:** `ready` is now LOAD-BEARING for dispatch — a live runner with `r.sc.ready` absent gets SKIPPED. Safe because every normally-live runner carries ready:1 (advertise sends ready:1; ping beacon sets ready:true; roster line ~1252 stamps r.sc.ready=1); ONLY a going-cold advertise clears it. If you ever see "live runner never gets jobs", check whether something cleared its ready. Related: [[runs-broadcast-both-runners-fix]].
