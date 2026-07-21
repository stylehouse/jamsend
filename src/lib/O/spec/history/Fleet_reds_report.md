> **HISTORICITY — retired to history/ 2026-07-21 (thinning the small specs).** A **point-in-time
>  snapshot** of 17 red Books taken 2026-07-07 on the since-merged `perf/gallop-tighten` branch —
>   most of the reds it classifies were the Voro-guts WIP stale-fixture wave, long since re-recorded.
>    A reds snapshot goes stale on contact; **current fleet truth = a live `runner_ask` sweep + the
>     Credence board**, never this file. Kept only for its cause-taxonomy (stub / runner-killer /
>      stale-fixture / env-gap), which is still a useful lens when triaging a fresh red.

# Fleet reds report — the 17 Books red on the live runner (gallop-independent)

Generated 2026-07-07 (eve) on branch `perf/gallop-tighten`, live :9091 runner. These 17 Books are
red **with Technique A's gallop DISARMED too** (proven by a reds-only control sweep), so **none are
caused by the perf lever**. This report classifies WHY each is red and what fixes it.

**Headline:** the 17 collapse to a handful of *causes*, not 17 mysteries. The biggest is a **stale-
fixture wave from the "Voro guts" commit (610c2575)** — which rewrote `Cytui.svelte` (358 lines),
changing cyto snap *format + content + labels* — whose cyto-touching Books were never re-recorded.
That commit + `fb6b257c` are on THIS branch line but not `main`, so several of these reds belong to
the Voro-guts WIP, not to anything broken. Two Books **hang the runner tab** (peering standup) and must
be quarantined from unattended sweeps. Two are **unauthored stubs**. The rest are stale/wrong/ordering
fixtures and env gaps (`/music`, peer topology).

## Summary table

| Book | class | fail@ | one-line cause | fix | conf |
|---|---|---|---|---|---|
| AwFloat | **stub** | 1 | placeholder dige `a0a0…`, zero snap files — never authored | delete or author | high |
| Educarium | **stub** | — | placeholder dige `0000…`, zero snap files — never authored | delete or author | high |
| MusuBounce | **runner-killer** | 2 | two-sided DJ↔Crowd peering standup HANGS the tab | code (peering); quarantine | high |
| Editron | **runner-killer** | 1 | peering standup HANGS the tab (same signature) | code (peering); quarantine | high |
| Peeringinst | peering (wedge-victim) | ? | never dispatched — poisoned by a prior wedge; peering-class | isolated retry; likely same wedge | med |
| MusuReplica | env/topology | 12 | missing `%see:…wire traffic folds…` — single-box loopback doesn't fold the wire | re-record or 2-box | med |
| MusuRadio | env-music | timeout | 65s audio timeout, `/music` is empty | mount `/music` | med |
| MusuTune | env-music | timeout | 65s audio timeout, `/music` is empty | mount `/music` | med |
| VoroMitosis | **stale (Voro guts)** | 4 | `cell:Pittosporum`→`Metrosideros` label rename not re-recorded | re-record | high |
| LeafFarm | **stale (Cytui rewrite)** | 5 | cyto snap format flat→JSON + labels changed | re-record | high |
| LeafJuggle | **stale (Cytui rewrite)** | 1 | got now emits a `Snap:cytowave` block the fixture lacks | re-record | high |
| Interesting | **stale (Cytui)** | 1 | `Snap:cytowave` block delta | re-record | med |
| Snapmigrating | stale (month-old) + multi | 1 | old `ttlilt`, missing wormhole-listing state, `%see`, cytowave | re-record + check wh-list | med |
| PortPain | **wrong fixture** | 1 | its `001.snap` is *PortPlan's* snap (clone never re-recorded) | re-record or delete dup | high |
| Diffmatication | cross-book drift | 1 | fixture embeds `Story/LakeTiles` toc, which drifts as LakeTiles runs | re-record; fragile by design | med |
| MundaneStaying | ordering flake | 1 | `req:one_shot` child order (line 6↔7), identical content | near-pass; re-record/ignore | high |
| ReactiveWaft | ordering flake | 2 | `self,round` order + a `mo:main` line | near-pass; re-record/ignore | high |

## Causes, ranked by Books unblocked

1. **Re-record cyto/Voro fixtures after the Cytui/Voro-guts rewrite** → VoroMitosis, LeafFarm,
   LeafJuggle, Interesting (**4**). Confirm the new Cytui output is the intended one (it's a deliberate
   358-line rewrite, so almost certainly yes), then re-record via a live Story Accept. Biggest lever,
   lowest risk. These likely pass on `main` (old Cytui + old fixtures) — they're Voro-guts WIP debt.
2. **Fix the peering-standup hang** (CODE) → MusuBounce, Editron, Peeringinst (**3**). Highest-value
   code fix — it also stops the runner-killing that costs a reload-interval per hit. NOT secure-context
   (human confirmed the tab is `localhost:9091`). Needs the tab console: freeze (busy-loop) vs stall
   (never-resolving await). See §MusuBounce.
3. **Mount `/music`** → MusuRadio, MusuTune (**2**). Sandbox gap (`Dev_instance.md` §5). Empty `/music`
   → audio Books time out.
4. **Re-record misc stale/wrong fixtures** → PortPain (wrong Book's snap), Snapmigrating (month-old),
   Diffmatication (cross-book), MundaneStaying + ReactiveWaft (ordering) (**5**).
5. **Delete or author the stubs** → AwFloat, Educarium (**2**). Recoverable from `main` if deleted.
6. **MusuReplica** (**1**) — the missing wire-fold `%see` is likely single-box-topology; re-record or
   run 2-box.

---

## Per-Book detail

### AwFloat — STUB (delete candidate)
`toc.snap` step line is `step,dige:a0a0a0a0a0a0a0a0` (a placeholder sentinel) and there are **no
`NNN.snap` files**. Never authored; red by construction (no real fixture can match a placeholder dige).
Step 1 produces a 103-line snap (dige `e458…`) with nothing to compare to. **Fix:** delete
`wormhole/Story/AwFloat/` (tracked on `main`, so recoverable) or author it. Human: "no idea what
AwFloat is anymore, perhaps delete it." — do it on its OWN branch, not the perf branch.

### Educarium — STUB
Same class: `step,dige:0000000000000000`, no snap files. Delete-or-author.

### MusuBounce — RUNNER-KILLER (peering wedge) ⚠ quarantine
Step 1 passes; **step 2 hangs the runner tab**: dispatch → `stepping` → silent >25s → dead to ping.
The wedge outlasts a whole Book, so the NEXT Book in a sweep gets "no reply in 12s" (it poisoned
Peeringinst here). Step 2 is the **DJ↔Crowd two-sided peering standup** — `002.snap` shows
`Peering,name:DJ / Pier,pub:Crowd` and the reverse `Peering,name:Crowd / Pier,pub:DJ`. The human saw a
think-loop (`todo:think → beliefs:begin think → think:MusuBounce→MusuBounce` cycling), which suggests a
busy re-arm, not a clean idle. **NOT secure-context** (tab is localhost). Root cause unknown — a peering
handshake that never resolves. **Needs the tab console (§console asks below).** Quarantine from
unattended runs meanwhile.

### Editron — RUNNER-KILLER (peering wedge) ⚠ quarantine
1-step Book, **wedges inside step 1** — identical dead-tab signature to MusuBounce. Peering-class
(1 peer-snap). Same investigation; same quarantine.

### Peeringinst — peering, wedge-victim
`run: no reply in 12s` — it never dispatched because the MusuBounce wedge was still active. Peering-class
(2 peer-snaps). Needs an **isolated retry on a fresh runner**; expect it may wedge too. Not yet
characterized on its own.

### MusuReplica — env / peer topology
Ran cleanly to **step 12** (of 14) — so peering standup itself WORKS here; it does NOT wedge (contrast
MusuBounce/Editron). Fails on one missing assertion:
```
< see:the wire traffic folds — each inbox and outbox rides as one stuffed chunk
```
This `%see` about **wire-traffic folding** (message batching into one stuffed chunk) never became true.
Likely the single-box loopback doesn't batch the wire the way a real second transport did when recorded.
**Fix:** re-record here, or run 2-box. Alt hypothesis: a real regression in chunk-batching (human can
distinguish).

### MusuRadio / MusuTune — env-music
65s timeouts; capture auto-released before a step recorded (`book:null`). Real-audio Books waiting on
tracks that aren't in the **empty `/music`** mount (`Dev_instance.md` §5). **Fix:** mount `/music`.
Medium confidence (didn't get a clean failing-step, but timing + audio-Book + empty mount align).

### VoroMitosis — STALE fixture (Voro guts) ★ re-record
Step 4, clean 10-line diff — a pure **content rename**:
```
< cell:Pittosporum      >  cell:Metrosideros
<   Pittosporum:robusta  >    Metrosideros:robusta   (+ propinqua/rhamnoides/grandifolia)
```
The Voro cell genus was renamed Pittosporum→Metrosideros in the "Voro guts" work; step-4's fixture wasn't
re-recorded. Matches the human's "VoroMitosis changed a bit." **Fix:** re-record. High confidence.

### LeafFarm — STALE fixture (Cytui rewrite) ★ re-record
Step 5, 62-line diff. The cyto upsert **snap format changed** — fixture `upsert,id:cytoid_1_1,label:farm`
(flat) vs got `{"upsert":1,"id":"cytoid_1_1_2","label":"poo\ndose:1.26"}` (JSON object) — plus label
content (`farm/sunshine`→`poo/dose`). This is the `Cytui.svelte` 358-line rewrite changing cyto
serialization. **Fix:** re-record.

### LeafJuggle — STALE fixture (Cytui rewrite) ★ re-record
Step 1, 100-line diff — got **ADDS a whole `Snap:cytowave` block** (`upsert,id:cytoid_1_1,label:Yin,…`)
that the fixture lacks. Proves the runner **is** rendering Cyto (refutes any "runner Cyto-less" theory);
the fixture simply predates the rewrite that now emits cytowave. **Fix:** re-record.

### Interesting — STALE fixture (Cytui) re-record
Step 1, 12-line diff — a `Snap:cytowave` block present in the fixture, absent from got (old flat format
deleted; got emits the new shape elsewhere). Same Cytui-rewrite family. **Fix:** re-record. Medium
(didn't fully reconcile the format both directions).

### Snapmigrating — STALE (month-old) + multi-factor
Step 1, 85-line diff. Fixture is ~a month old (`ttlilt until_ts=1780584327` ≈ 2026-06-04). Three
factors: (a) `req:Store` in a different state (fixture has a `req:wlisting,rw_dir:wormhole,rw_op:list`
+ waiting ttlilt; got has `req:Store,eternal,maz=7,ok`), (b) the migration `%see`
(`✅ Snapmigrating: 0 migrated…`) absent, (c) a `Snap:cytowave` block. **Fix:** re-record; if the
wormhole-listing state is genuinely wrong (not just stale), check wormhole access on the runner.

### PortPain — WRONG fixture ★
Step 1, 10-line diff — the fixture is **a different Book's snap**: got `H:PortPain/A:PortPain/w:PortPain`
vs fixture `H:PortPlan/A:PortPlan/w:PortPlan` (+ `De:sort/req:wait` `De:yay` that look PortPlan-specific).
PortPain was cloned from PortPlan (family: PortPlan/Planet/Plant/Pain) and its `001.snap` was never
re-recorded. **Fix:** re-record if PortPain is a real distinct Book; delete if it's an accidental dup.

### Diffmatication — cross-book drift
Step 1, 55-line diff. The fixture embeds a **wormhole read of another Book's toc**:
`requesty_wh:1,wh_path:Story/LakeTiles,wh_op:read_toc`. Got shows LakeTiles's `The` with current
step diges — i.e. the read returns LakeTiles's toc, which **drifts every time LakeTiles runs** (and it
ran heavily today). Inherently fragile cross-book dependency. **Fix:** re-record; consider decoupling it
from a live Book's toc.

### MundaneStaying — ordering flake (near-pass)
Step 1, 2-line diff — a `req:one_shot,ttl=600,timer=400,finished` child on fixture line 6 vs got line 7,
**identical content, different position**. Benign Travel-order non-determinism. Re-record or ignore.

### ReactiveWaft — ordering flake (near-pass)
Step 2, 3-line diff — `self,round=2` ordering + a `mo:main,interval=3.6` line. Same near-pass class.

---

## Notes / caveats
- **Method:** each Book run once via `runner_ask run --watch`; first `ok:0` step → `snap` → diff vs
  `wormhole/Story/<Book>/<NNN>.snap` → `trace` for shape. Captures under
  `scratchpad/diag/<Book>/`. Runner-killers and audio-timeouts didn't capture a clean failing step.
- **The runner drifts + the two killers cost downtime** — a couple of "no failing step" reads are
  wedge/dispatch artifacts, not "no failure." Re-run the medium-confidence ones on a fresh runner to firm
  them up (avoid MusuBounce/Editron unattended).
- **These reds are on the Voro-guts branch line** (610c2575 + fb6b257c, not in `main`). The cyto/Voro
  stale-fixtures are Voro-guts WIP debt and likely pass on `main`; they are independent of the perf lever.

## Console asks for the peering wedge (MusuBounce/Editron) — the one thing the relay can't see
1. **Freeze vs stall:** when it wedges, is the tab frozen (can't scroll/type, a core pegged at 100%) —
   or idle (DevTools responsive, just nothing happening)? Freeze ⇒ infinite sync loop; idle ⇒ an
   `await` that never resolves.
2. **Spamming?** repeating console lines (esp. `🔥 burning CPU on stuck pending`, repeated `think`, or
   `NN.NNN ▶ …` tlog rows) — paste ~5.
3. **Red error / unhandled rejection** — top one verbatim, esp. `RTCPeerConnection`/ICE/`DataChannel`/
   peerjs/`Pier`.
4. **Network tab:** is `/relay` still `101/open`? any WebRTC conn stuck `checking`/`connecting`?
