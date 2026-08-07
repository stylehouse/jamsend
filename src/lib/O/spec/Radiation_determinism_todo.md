# Radiation_determinism_todo.md — why the Ra* Books cannot be re-recorded yet

Scope: the `Radiation.g` Book family (**MusuRaStream**, MusuRaChase, and the retired-into-MusuBuddy
 siblings). Written 2026-08-08 from three back-to-back live-runner runs of MusuRaStream at one
  unchanged build. It exists because a re-record was approved and then **blocked**, and the next
   person needs to know exactly what blocks it.

`Radio_todo.md` was being written by a concurrent agent at the moment this landed (it grew 3.5 KB
 while this was being composed), so this went to its own file rather than risk clobbering it.
  **Fold this into `Radio_todo.md` §3.4 / §9.3 and retire this file to `spec/history/` once the
   contention is over.**

---

## 0. What to get on with next

1. **Do not `accept`.** Re-recording MusuRaStream today bakes a *starve* and a *coin flip* into the
   fixture. See §3 — the number of dropped segments takes at least two values across runs, and the
    Book's central claim (`fed:`) never fires at all on the live runner.
2. **The real bug to chase is §3, not §2.** The Book's on-demand transcode does not reach the
   playhead before it crosses the preview boundary. The fixture says `a_drops=0`; the live runner
    gives 2 or 4, every time, on every run. That is a product regression (or a product truth the
     fixture never actually held), and it is upstream of every determinism question.
3. Only once `a_drops=0` is reproducible three runs running does the re-record become safe — and
   even then, re-record **only** at a quiet build with nothing uncommitted in `Ghost/M/Ra.g`.
4. §4 lists the two candidate fixes for the pacing race, both of which need the human's call
   because both are `.g` edits in files a concurrent agent has been touching.

**The arc:** MusuRaStream is meant to be the end-to-end proof that the preview economy works over a
 real wire — hold at the boundary, ask at the boundary, and get *fed across it* by a demand-driven
  transcode. Right now it proves the first two and fails the third, and the failure is intermittent
   in degree. Getting it green is what makes the whole Ra* family a gate again.

---

## 1. Method (so the numbers can be re-derived)

Runner **a67a5d04a04fd334**, courted with `runner_ask.mjs ping --runner=…` first (the `running` slot
 held a finished Book name, not a `Ghost/**.g` path — 58517b48 was squatted by a `Ghost/N/Peeroleum.g`
  compile and is unusable). Three runs, **R1 / R2 / R3**, back to back, no reload, no compile between
   them. Per run: `steps` for the diges and all forty `snap <n>` captured *before* the next run
    started (only the latest run's snaps survive).

Build was verified unchanged across the three: `Ghost/M/Ra.g` last written 23:17 → compiled 23:24;
 `Ghost/Story/Radiation.g` last written 23:36 → compiled 23:37; both untouched during R1–R3.

**Correction to an inherited premise.** Earlier evidence in this session compared a 23:07/23:16
 capture against a 00:08 one and called them "the same build". They are not — `Ghost/Story/Radiation.g`
  was recompiled at 23:37, between them, and `Ghost/M/Ra.g` at 23:24. The only sound within-build
   comparison in that older set is `a.txt` vs `b.txt` (both 23:16), which diverge at **step 14** —
    and that agrees exactly with what R1–R3 show below. The "step 2 varies" claim was a build
     artefact plus §2's counter, not a content race.

---

## 2. Instability #1 — `self,round` is snapped and is a wall-clock quantity

Steps **1 through 13 are byte-identical in content across all three runs**. Their *diges* still take
 three distinct values, and the entire difference is one token:

    self,round=13     (R1)
    self,round=12     (R2)
    self,round=14     (R3)

`self,round` is the belief-pass counter (`Hovercraft.svelte:38-42`, `self_timekeeping`). A Story step
 is `schedule()`'s fixed 200 ms plus a `poll_step` loop ticking every `TICK_MS`=50 ms until the world
  goes quiescent, so **how many belief rounds fit inside one step is a function of the wall clock**.
   The live telemetry (`runner_ask world`) shows the spread directly:

    quiesce  step=11  tick=50  secs=0.45  in_Atime=8
    quiesce  step=12  tick=50  secs=0.15  in_Atime=2
    quiesce  step=15  tick=50  secs=0.87  in_Atime=16

1 to 4 belief rounds per step, drifting run to run, and the drift is **cumulative** — one extra round
 at step 5 offsets every subsequent step's counter for the rest of the run.

**This one is already handled and is NOT the blocker.** `Story.svelte:1074-1097` carries a v2
 EntropyArrest spay for exactly this: `spay: { re: '\\bround(?:=\\d+)?\\b', tol: 'any' }`, which
  grafts got's round onto exp's unconditionally at compare time. So a `self,round` drift becomes a
   **caveat, not a failure**. The trap for a reader is that the **dige is computed before the graft**,
    so *diges differing is not evidence a step would fail*. Judge re-record safety on the normalised
     snap diff, never on the dige list.

There is one real §2 side effect, at step 2 only: with fewer rounds in the step, the `%req:witness`
 gets one fewer pass and the once-noticed
  `see:two real opus Records stand at the caster …` lands at step 2 in R2/R3 but only at step 3 in R1.
   A `%see` slipping a step is a genuine fixture mismatch, not a spayed one.

---

## 3. Instability #2 — the demand transcode loses a race to the playhead (THE BLOCKER)

**First content-unstable step: 14.** R1 and R3 agree there; R2 differs by 35 lines. At step 15 all
 three differ; the split then persists to step 40.

What actually varies at step 14 — R1 vs R2, everything else identical:

    R1 (behind):   parked_want,id:d71294dbbcd7b726,stream:opus,from_idx:16
                   parked_want,id:d71294dbbcd7b726,stream:opus,from_idx:18
                   (no %Stream chunks at the mirror)

    R2 (ahead):    Stream,seq:16 … Stream,seq:38   (23 chunk particles landed)
                   + 6 matching req:unemit repli_page/repli_lines rows

Same cause as §2: `MusuRaStream_drive` advances the playhead **once per step** but runs
 `peering.do()`, `Ra_transcode_pump(w)` and `MusuRaStream_flow(w)` **once per pass**. R2 got 4 belief
  rounds inside step 14 (round 31→35); R1 got 2 (32→34). Twice the pump, and the whole continuation
   arrived a step earlier. `Radiation.g:123-145` already names this exact mechanism.

### 3.1 It is not merely a phase shift — it changes the measured audio

The divergence lands in the Book's own observed rows, which are the assertions:

| run | `switched` | `streamed` |
|-----|-----------|-----------|
| R1  | `at_head=20,a_dropped=4` | `a_drops=4,a_heard=160,b_drops=2,b_heard=80` |
| R2  | `at_head=20,a_dropped=2` | `a_drops=2,a_heard=80, b_drops=2,b_heard=80` |
| R3  | `at_head=20,a_dropped=4` | `a_drops=4,a_heard=160,b_drops=4,b_heard=160` |

Three runs, three distinct `streamed` rows. `a_drops` ∈ {2,4}, `b_drops` ∈ {2,4}, and `a_heard` /
 `b_heard` are 40 ms of silence per dropped segment. Nothing spays these — they are Book rows with
  real values. **A fixture recorded from any one of these runs fails the next run.**

### 3.2 The Book's central claim never fires at all

No run emitted a `fed:` row. The gate is
 `map2[p.preview] != null && p.drops.indexOf(p.preview) < 0` — the boundary chunk must be present
  **and not have been dropped**. Since seg 16 is inside the drop set every time, `w.c.fed_a` is never
   set, so:

- `req:crossing` never goes `ok` — it reads `req:crossing,eternal` (no `,ok`) from step 12 through
  step 40 in every run. The 2026-08-06 "crossing hold" is *permanently engaged and not delivering*.
- The switch to track B happens on `r.done` (the 20-chunk cap), not on the fed proof — hence
  `at_head=20` = `cap`, in every run.
- **Two of the seven `%see` claims never fire**: *"the playhead crossed the boundary onto transcoded
  chunks that arrived on demand"* and *"the next track played its capped cycle clean — the transcoder
   kept ahead of a fresh playhead"* (`b_heard <= 3` vs an actual 80–160).

The recorded fixture `040.snap` has `fed:A,at_head=18,held=4`, `switched,at_head=20` with **no**
 `a_dropped`, `a_drops=0,a_heard=0,b_drops=0,b_heard=0`, and all seven `%see`. So the fixture
  describes a world where the transcode kept up. The live runner never reaches it.

**Read that carefully before assuming a regression.** It is equally consistent with the fixture
 having been recorded on a machine (or a headless boot) fast enough to win the race — which is what
  `Radiation.g:137` already warns about ("two clean accepts still verified 0.33 and 0.23"). Either
   way it is a product question, not a fixture question.

---

## 4. Stale fixtures — the separate, already-known cause, now measured exactly

With `now=` and `self,round=` normalised out, the residue against the recorded fixtures is:

    step  1 :   0 lines     ← step 1's ENTIRE diff is the clock pin
    step  2 :   5 lines
    step  5 :  60
    step 13 : 149
    step 40 : 229

Step 1 normalising to **zero** confirms the inherited diagnosis exactly: the fixtures predate
 `Radiation.g:78`'s `w.sc.now = 1751980000 + 10*n`.

Two further stale-fixture causes, both source changes the fixtures never saw:

- **The swarm clock was live when they were recorded.** Fixture rows carry
   `Pier,…,since:1785076033`, `Edge,…,at:1785076033`, `Grant:Music,…,time:1785076033` — a real
    2026-08-06 wall clock — against the live `1751980040`. Every `Grant` **signature** differs too,
     because the ed25519 `sign` is computed over that time. That is 8 `Grant` + 4 `Pier` + 4 `Edge`
      lines in every snap from step 5 on, i.e. it alone reds every late step.
- **`%Record` gained `path:`.** Live: `…,real,col,path:testsounds/DJ Oscillo - Cosmic C.wav,sr=48000,…`
   Fixture: `…,real,col,sr=48000,…`. 2 lines per snap from step 2 on.

Residue at step 40 by mainkey (the categorise-don't-read trick):

    113 unemit    47 emit    37 Stream    8 Record    8 Grant
      4 Pier       4 Edge     2 switched   2 streamed  2 see   1 req   1 fed

The `unemit`/`emit`/`Stream` bulk is §3's starve (chunks that never crossed, and outbox depth that
 therefore never matched); `Grant`/`Pier`/`Edge`/`Record` is stale fixture. They are genuinely two
  causes and re-recording only fixes the second.

### 4.1 `pv_off` is a red herring — do not chase it

An earlier capture in this session (23:07) showed `Record,…,total=25,pv_off=14` where R1–R3 show
 `total=39` and no `pv_off`. That capture was taken during a **controlled revert** (a `Ra.g.mine`
  copy sits in the session scratchpad), not at the current build. `Ra_stock_one` gates the cut point
   on `top_House().c.humdinger`, so a `?B=` Book runner always stocks at offset 0 and pv_off never
    appears. Current runs confirm it: no `pv_off` in any of R1/R2/R3. Nothing to fix here.

---

## 5. Can re-recording ever be safe without a code fix?

**No, not today.**

- §2 (`self,round`) alone *would* be survivable — the spay forgives it — except for the step-2 `%see`
  slip, which is a one-step-window problem and is arguably already covered by the `n >= 2` idiom the
   witness uses.
- §3 is fatal. `a_drops`/`a_heard` take at least two values at a fixed build with nothing else
  changing, and they are plain values in a snapped row with no tolerance. Whichever run is accepted,
   the next run has a ~50% chance of contradicting it — which is precisely the "two clean accepts
    still verified 0.33" history the Book's own header records.

### Candidate fixes (proposals only — all are `.g` edits, and `Ghost/Story/Radiation.g` is mode 664,
### i.e. a concurrent agent's file. **Not applied. The human's call.**)

1. **Make the crossing hold actually hold on the thing that matters.** `req:crossing` currently
   releases on `w.c.fed_a`, which can never be set once seg 16 is in `p.drops`. Holding instead until
    the *boundary chunk has arrived* (`Ra_chunk_map(rec)[p.preview] != null`), **before** the beat
     that would play and drop it, converts a timing race into a causal wait — which is the one shape
      that works here, because the pumps are pass-driven and a delay buys real arrivals.
2. **Decouple the pumps from the pass count.** Give `Ra_transcode_pump` a per-step work quota rather
   than letting it run once per belief pass, so a step's transport progress stops being a function of
    how many rounds happened to fit. Bigger change; more likely the right one long-term, since the
     same race is what `Radiation.g:123-145` says reds MusuRaChase at 13-of-56.
3. **If the starve turns out to be the honest product truth** (the encoder simply cannot keep ahead of
   a 2 s/segment playhead at this cap), then the assertions are wrong, not the world — `b_heard <= 3`
    and the `fed:` claim need re-tuning against measured reality, and *that* is a re-record the
     numbers would justify. Deciding between this and (1)/(2) is the next real piece of work.

---

## 6. Operational notes worth keeping

- **`ping` before every run.** 58517b484a8e896d had `running.book: "Ghost/N/Peeroleum.g"` — a
  ghost_compile squatting the run slot. That runner wedges every Book at phase `begun`.
- **A runner tab can reset mid-run.** One run here died at step 32 with `running` and `engagement`
  both going `null`. Nothing in `state` distinguishes that from a stall except the reset itself; the
   `--watch` client just prints `runner quiet 13s/20s` and then `{"run":null}`.
- **`--watch` is not a completion signal** and its exit code is not a verdict (already in the memory
  file, re-confirmed here). Poll `state`, gate on `run.book`, and treat "`done` stopped advancing"
   as settled — MusuRaStream reliably parks at `phase:"stepping", n:40` without going terminal.
- MusuRaStream costs ~30–40 s of wall clock for 40 steps on a warm runner, plus ~90 s to pull all
  forty snaps over the relay. Budget ~3 min per sample.
