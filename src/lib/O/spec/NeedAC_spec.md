# NeedAC — securing AudioContext *before* a Story run

Status: DESIGN + partial build. Cross-boundary (Story-runner / Lies / Networking). This doc is the
 handoff so the Lies and Networking agents can wire their halves. Author: Story-runner side.

> **UPDATE 2026-07-03 — §6 is CLOSED (uncommitted, :9091-verify owed).** All five gaps landed:
>  §6.1 the click path carries the cell's needAC (`Storying.svelte` → `e_Lies_become_book`);
>  §6.3 `runner_ask run` reads Credence and passes needAC; §6.4 the editor Brink shows
>  `awaiting_audio`/`audio_blocked` as a 🎤 Upkeep errand (`Lies_run_phase_recv`).  And the §3
>  coupling is now honoured — **advertise first, then match**: a runner's ~15s beacon carries
>  `ac:1` when its AudioContext is gesture-unlocked (`Lies_advertise` probes the shared
>  `top_House().c.musu_gat` cache), the roster folds it to a snapped `%Runner,ac` facet, and
>  `Lies_dispatch_target(w, needAC)` PREFERS an ac-live runner above every favour tier — prefer,
>  never require, so a fresh fleet (no AC granted anywhere yet) still dispatches and begs.  Held
>  (`Lies_drain_runs`) and swept (StoryTimes) runs re-read the board via `Lies_book_needac(w, book)`
>  since their queues carry only names.  §6.5 resolved DIFFERENTLY: `Musu_gat`'s soft-path
>  `AudioContext_wanted` still fires, but the surface it reaches is now the small self-gating Sound
>  Brink beg on both roles (the Otro fullscreen pop is suppressed under dev boots), which is the
>  behaviour the de-nag wanted — a quiet ask, not a takeover; its cache was already canonical on
>  `top_House().c.musu_gat`.  Still open: §3/§6.2 %rungo routing (staged by design, D1) and D3's
>  lapse policy on the editor board.

## 1. Principle

A Story whose ASSERTIONS need real audio (an online `AudioContext`) must have it secured **before the
 run begins** — never wait-for-AC in the middle of a run. The wait must sit *outside* every step's
  clock, so the run's timing and verdict are never entangled with how long a human took to grant the
   gesture.

Two surfaces during the pre-run wait:
- **FaceSucker on the runner tab** — the "open share" gate, so a human at that tab can grant AC.
- **Brink-complain on the editor** — so the operator/dispatcher sees "runner X is holding, needs AC."

If AC is never granted within the window: the run **does not start** and is reported **blocked /
 UNTRIED** — `!ok`, carries an error, but *nothing was tried*. It must read as "couldn't run here",
  NEVER as "the audio delivery is broken" (same honesty line as offline-vs-real-time).

## 2. The marker — `%Storying,needAC`

Flat marker on the Credence board cell (NOT the hierarchical `^^What/RunnerAdvice` yet — deferred):

```
wormhole/Credence/toc.snap
  Funkcion:Storying,of_Book:MusuRadio,needAC:1
  Funkcion:Storying,of_Book:MusuTune,needAC:1
```

DONE. These two carry audible play steps (MusuRadio_play / MusuTune_show).

## 3. Authority (staged)

Stay on `become_book` for now (loose — runs whatever's live). The eventual want is `%rungo`: a
 currency-gated authority that waits for the exact compiled dige before firing, so a verdict provably
  matches the source you pushed (the controlled edit→compile→verify push) — needs fleet coordination we
   don't have yet, ~mid-Jul 2026. The two begin-paths are a known dev ugliness, cross-noted in-source at
    each begin-fn (`Lies_become_book_drive` / `req_rungo`). `Lies_secure_audio` (§5) is identical either
     way, so staging wastes nothing.

**Coupling:** land audio-capability advertising BEFORE the needAC dispatch-match — a needAC run must be
 able to require an audio-advertising runner. Advertise first, then match.

## 4. The flow (target)

```
Credence cell  ──needAC──▶  %rungo / authority (editor)
                                 │  reads needAC for the Book
                                 ▼
                      tell the runner: "become Book X, needAC"
                                 │
                    ┌────────────┴─────────────┐
                    ▼                            ▼
        runner: FaceSucker (open share)   editor: Brink-complain
                    │  human taps                 │  "runner X holding, needs AC"
                    ▼                            ▼
        runner: AC live? ──yes──▶ run begins (verdict is clean)
                    │
                    └──60s lapse──▶ run refused → BLOCKED/UNTRIED reported up
```

## 5. What is BUILT (runner side — this repo, now)

- `Lies_become_book_drive(w, book, needAC=false)` (LiesFunk.svelte) — the runner's single run FRONT
   DOOR. When `needAC`, it awaits `Lies_secure_audio` BEFORE `resetStory`. If not secured → does not
    begin; emits phase `audio_blocked`.
- `Lies_secure_audio(w, book)` (LiesFunk.svelte) — probe/create `top_House().c.musu_gat`; if cold →
   `AudioContext_wanted` (→ Otro's "open share" gate on this tab) + `Lies_runner_phase(w,
    'awaiting_audio', {book})` (the Brink-complain signal up the run channel) + SIT ≤60s polling
     `AC_ready` → true when live, false on lapse.
- `Lies_become_book_recv` passes `!!frame.needAC` through.
- Otro's merged gate already renders the FaceSucker off `AudioContext_wanted`.
- Story's generic UNTRIED verdict (`w.c.step_blocked` → `step.sc.{ok:false, untried:true, error}`)
   exists for a per-step block; the pre-run refusal currently uses the `audio_blocked` phase instead.

All type-clean; MusuStream 5/5 green (non-regression — every non-needAC caller passes 2 args → no gate).

## 6. What is MISSING (the gap that caused the symptom)

The observed bug — "FaceSucker pops mid-Story (step 4), nothing in the Brink" — is because **no
 authority carries `needAC` from Credence to the runner.** Precisely:

1. **Read Credence needAC.** `Lies_send_become_book` (editor) and the `storying_run` launch path do NOT
   read the funk's `needAC`. → the runner's `frame.needAC` is always undefined → the pre-run gate never
    fires. **[Lies agent]**
2. **Route via `%rungo`.** Decide + wire §3 so the securing is a run-authority responsibility, not a
   `become_book` afterthought. **[Lies + Networking]**
3. **`runner_ask run`** (LiesFunk ~1084) passes 2 args → add `!!ask.needAC` so a CLI run can gate too
   (needed to verify headlessly with a short timeout). **[Story-runner — trivial, mine]**
4. **Editor Brink surfacing.** Nothing renders `awaiting_audio` / `audio_blocked` on the editor. The
   phases are emitted up the run channel; the Brink face must show them (a row/badge: "runner X — needs
    AC", and "blocked — AC not granted"). **[Networking — owns the roster + Brink]**
5. **Soft `Musu_gat` de-nag.** `Musu_gat` (Musuation.g) still fires `AudioContext_wanted` when cold —
   this is the mid-Story pop the user saw. Once AC is secured pre-run, step 4 finds it ready and won't
    pop; but a showcase on a tab that DIDN'T pre-secure would still pop. Stop `Musu_gat` firing the
     event (it's the SOFT/optional path — showcase, skip-if-absent) and canonicalize its cache to
      `top_House().c.musu_gat`. **[Story-runner / Lies — .g recompile]**

## 7. Ownership split

- **Story-runner (me):** the runner-side gate (§5, done), `runner_ask needAC` (§6.3), soft `Musu_gat`
   de-nag (§6.5), the UNTRIED/blocked verdict semantics (§8).
- **Lies agent:** read `needAC` from Credence at launch (§6.1); route Book runs through `%rungo` (§3/§6.2);
   `Storying`/`storying_run` launch path.
- **Networking agent:** the `%rungo`/`become_book` protocol carrying `needAC` (§6.2); the editor **Brink**
   surfacing of `awaiting_audio`/`audio_blocked` (§6.4); the relay/roster; cross-tab focus (§9).

## 8. Verdict semantics

A run that can't secure AC ⇒ **blocked / UNTRIED**, distinct from pass/fail: `!ok`, has `error`, nothing
 tried. The run authority reports it as "couldn't run here." On the editor board it should read visibly
  different from a red (e.g. a ⌛/grey state), so a headless/no-AC runner doesn't smear a needAC Book red.

## 9. Cross-tab focus (attention)

The `awaiting_audio` report reaches the editor fine over the relay. FOCUS (yanking the human to the
 runner tab) is the browser-limited part:
- `<a target="name">` focuses another tab **only** if the editor OPENED it (same browsing-context
   group). Independently-launched fleet tabs can't be focused this way.
- Reliable regardless: runner **self-signals** — flash `document.title` / swap favicon / `setAppBadge`.
- True click-to-focus for independent tabs needs a service worker + Notification (`notificationclick`).
Recommendation: Brink-complain (report) + runner self-signal; add editor-opener focus only if the fleet
 is editor-spawned.

## 10. Open decisions

- D1. Route Book runs through `%rungo`, or teach `become_book` to carry `needAC`? (§3)
- D2. Pre-run refusal: report via the `audio_blocked` phase (current) or reuse the per-step UNTRIED
   verdict at run level? (§5/§8)
- D3. Window length (currently 60s) and what a lapse does on the editor board (retry? park? drop?).
- D4. Later: promote the flat `needAC` to the hierarchical `^^What/RunnerAdvice` so a whole What-limb
   inherits it (deferred per user).
