---
name: musu-ra-book-entropy-reaccept
description: New Ra Book with a seal needs EntropyProfile Wref:Trope/Ra/AudibleEntropy; accepting BEFORE the profile → dirty ≈-caveats → re-accept for clean diges
metadata: 
  node_type: memory
  type: reference
  originSessionId: 99e62ec8-06cf-4c57-990a-57905ed6dffa
---

Any Ra/Musu Book that seals a Pier (Grant `time:`/`sign:`, Pier `since:`) needs an EntropyProfile so those fresh-per-run fields don't red the fixture. The shared one: add at toc line 6 (sibling of Styles/Plan/Opt, before TimeSpool):

```
  EntropyProfile,Wref:Trope/Ra/AudibleEntropy
```

Defined at `wormhole/Trope/Ra/AudibleEntropy/toc.snap` — masks Pier since:, Grant/NotGrant time:+sign:, Edge at:, Record proof ms:. MusuRaStock/MusuRaCast use it; MusuRaTerm has NONE (fully deterministic, no wire).

**Mechanism (Hovercraft `entropy_rules`):** spay applies at ENCODE (enLine/snap_H), so the dige is over the SPAYED snap. Therefore **order matters**: accept the baseline, add the profile, then **RE-ACCEPT**. If you accept BEFORE the profile is on, the diges bake in raw timestamps; a later verify canonicalizes them to `{INT}` placeholders → every seal step becomes `ok:1,caveat:1` (≈ tolerated, taken-as-ok). Run is GREEN but "dirty" (e.g. MusuRaStream: 38/40 ≈ caveats). Re-accept WITH the profile → placeholders on both sides → clean green (caveat:0), permanent.

**CORRECTION (2026-07-11, proven live):** caveat:0 holds only for CANONICALIZING masks (placeholders on both sides). A **`tol:any` graft does NOT canonicalize — it tolerates change at diff time**, so a sealing Book shows a PERMANENT benign ≈ on exactly the grafted fields every re-run, even after a with-profile accept (family verify: Stream 40/40 ≈37, Cast 12/12 ≈9, Stock 5/5 ≈2 — all Pier `since:`/Grant `time:`+`sign:`/Edge `at:`; Term seals nothing ⇒ ≈0). Don't chase a phantom clean; each Book's caveat COUNT is its stable signature.

`runner_ask.mjs` HAS an `accept` op (RE-RECORD the live run's steps over the wire — the sanctioned path; CredRunner ACCEPT stays banned for %see-bearing Books). **HAZARD** [[accept-drops-proof-in-entropy-zone]]: a re-accept inside the entropy zone can silently drop a %see. Pre-pin the see set (`grep -aoE "%see:'[^']*'"` the .g), and after re-accept grep the live snaps to confirm all present (presence, not counts). Related: [[musurastream-real-streaming]], [[trope-entropy-profile-sharing]], [[see-is-not-a-latch]].

----
## merged from musu-ra-magazine-m2.md

---
name: musu-ra-magazine-m2
description: "MusuRa* do NOT use the magazine (they stock a %Library, never publish from it) though shapes fit; MusuVend = M2 magazine replication grant-gated, compile-clean + live-gate OWED"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2d6954a9-460d-42bd-afcf-4431dd33d952
---

**The MusuRa question (the human asked 2026-07-13):** do MusuRaStock/Cast/Term/Stream/Chase use the magazine "and otherwise reflect the current era?" Verified by Explore: **NO on the magazine** — the Ra family (`Ghost/M/Ra.g` + `Ghost/Story/Radiation.g`) stocks a real `%Library,pier > %Record` (+ `%Preview,seq`/`%Stream,seq` chunk particles, radiostock `<ts>-<pub>-<enid>` files) but publishes NO magazine (zero `Musica`/`%Cloud`/`Musica_publish` refs). **YES on current-era** — clean of tombstone, `%Tune`, and the old `<genre>/<Artist>/<Album>` tag-tree. The shapes ALREADY FIT: `Musica_fold` consumes exactly what `Ra_library` builds — nobody had wired them. Wiring the REAL Ra stock → magazine into the MusuRa Books is a follow-up (needs an FSA runner; owed).

**MusuVend = M2 (built 2026-07-13 pm, `Ghost/Story/Heistation.g`, appended after MusuHeist).** Two-Pier MAGAZINE replication grant-gated: Lake_link loopback, magazine folded in memory at the origin, `Repli_offer`ed WHOLE (husk — a magazine card is a payload-less leaf so no wants; whole tree crosses in ONE frame, `Repli_merge` upserts under the follower's mirror lib). The GATE is the point — `w.c.grants.Follower` toggle read by `w.c.repli_allow`: draw A crosses (granted) → draw B REFUSED+noted (revoked) → draw B catches up (re-granted, gate live not cached) → FORGET scene GCs the older cloud (Musica_forget_fold). 6 `%see` (absorbs BOTH owed-coverage items from the deleted MusuMagazine: multi-cloud grow = see #5, Musica_forget = see #6). Wire root is `%Mag,Musica` (the snappable shape MusuHeist's fold proved, NOT raw `%Musica` mainkey). DETERMINISTIC + in-memory: no FSA / no audio / no Berth / no AudibleEntropy → runs on ANY runner, jitter-free.

**State:** **LIVE-GREEN ×2 (2026-07-13, runner 49de): 11/11 steps, caveat:0, all 6 sees latched, both clouds distinct at follower, forget dropped the older cloud. Fixtures committed.** Registered Credence + Ality (brand_new dropped once green). ADVERSARIAL code review PASSED first (no RED bug, 5/6 sees breakable; see #2 catalog-not-payload is honest but semi-taut on the wire — leaf property = the FOLD's sublimation not husk; husk is a no-op for a payload-less magazine). `{Cloud:1}` is a numeric wildcard so `repli_loc` is load-bearing for see #5.

**RUNNER-OPS BOMB (learned live 2026-07-13):** the runner FROZE on first dispatch (`total:1` Prep-only bubble — the freeze problem) and **SELF-HEALED on the SECOND run** (frozen-boot: the first dispatch is a sacrificial thaw — see [[frozen-boot-empty-first-run]]). So on a `total:1`: don't give up — RELEASE, restore the clobbered toc from git (an orphaned save rewrites toc to a 1-step skeleton EVEN on a CHECK), then RE-RUN; the 2nd run often runs real steps. D1 part b (the sabotage wall) is now BUILT as [[musu-door-sabotage-wall]] (MusuDoor, LIVE-GREEN ×2); NEXT rung = D1 part a (harden the toggle into the live `Swarm_pier_live` door — the crypto part, reintroduces seal entropy, attended; Radio_todo §12.4). See [[magazine-cloud-shape]], [[stimuli-magazine-vision]], [[verify-via-live-runner]], [[pere-books-total-1]], [[adversarial-test-agent]].
