---
name: swarm-family-built
description: "Ghost/S Swarm family — Swarm.g spine + Swarmation.g SwarmStaple Book (crypto/identity, 10 %see); LIVE-RECORDED + verified green 2026-07-04"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

The Swarm_spec.md §8/§9 build landed 2026-07-03 (uncommitted): **`Ghost/S/Swarm.g`** (spine: `Swarm_mint_keys`
(Idento, seed→deterministic) / `Swarm_identity`+`Swarm_peering`+pruned `Swarm_page` / Idzeug = an UNBOUND
`mint_grant` for:'*' + nonce + page riding opt keys, `?Iz=` blob = utf8-b64 of the atom / wire seam
`Swarm_deliver`→`%mail`/`%frame` husks + `Swarm_pump` / `Swarm_redeem`→`pier_hello`(echo Idzeug + reciprocal
grant)→`Swarm_hello`(spend nonce, mint bound grant)→`pier_accept`→`Swarm_seal` (mutual %Pier + both grants +
%SocialGraph/%Edge each end) / `Swarm_revoke`→%NotGrant under the Pier, `Swarm_pier_live` checked at use) and
**`Ghost/Story/Swarmation.g`** (SwarmStaple, beats 2–7: sides up offline → mint → tamper+offline rebuffs →
seal → Carol replay-rejected → revoke; 9 `%see` claims). Both enrolled in CREDULER_GHOSTS (LiesLies.svelte).

**Why:** first .g family for the social side — proves the §2 particle model + §6 handshake end to end.

**How to apply:** iterate headless via `BOOK=SwarmStaple … scripts/CredRunner.spec.ts` (all-green, byte-
deterministic but for the Story `round=` counter — pins at live record like MusuSkip, or add the
[[trope-entropy-profile-sharing]] Wref). toc diges are LIES — record via `runner_ask.mjs run SwarmStaple
--watch` + `accept` on a live runner once one is unwedged (see [[runner-wedge-begun]]). Next slices:
Peeroleum `pier_hello` frames for real transport, `?Iz=` boot param in Auto, §4 Dexie⇄disk `Waft:Account`,
§5 auto-mint, 🪪 list/copy-snap. The bare-else mangle bit ONCE (Swarm_online) — C-style braces.

2026-07-03 pt 2: + portability (beat 8, `roundtrip:identical`): `Swarm_protocol`/`Swarm_export`(envelope
`{v,kind,snap,keys?}`)/`Swarm_import`/`Swarm_graft` (identity-key table finds twins — fresh nodes i()'d
with FULL sc so key order survives). + `Waft:Ghost/Swarm/Easy` (seeded in Lies_keep_reopen) + Credence
`What:Swarm` between Pere/Musu. TWO core Text.svelte encode fixes (PereProof 33/33 canary): omit_sc was
collected-never-APPLIED (saved Waft tocs leaked `active`); skip rules must prune in the PASS-1 dive
(pass-2 forward() is flat — a skipped node's children used to leak + re-parent a level up on decode).
GOTCHA: lematch doesn't know `{mk:…}` entries → reads them match-ALL → an mk-keyed skip rule skips
EVERYTHING (empty snap); skip rules must use `sc_has` presence probes.

2026-07-04: **LIVE-RECORDED + verified** (was OWED). Ran `runner_ask run SwarmStaple --watch` on the live
runner — all 8 beats reached, all **10 `%see`** fired (two-selves/keys-on-.c, single-use-Idzeug-Music-
Classical, tamper-rejected, offline-redeem-rejected, Bob-imported-page, reciprocity, social-graph-edge,
Carol-replay-rebuffed, NotGrant-retires-Pier, byte-faithful-roundtrip) + rebuffs (forged/offline/
rejected_spent) + roundtrip:identical. First run read "failed" only for want of fixtures (all `dige:0`).
`runner_ask accept` → re-ran → **GREEN 8/8, 0 caveat**, toc diges reproduced BYTE-FOR-BYTE across the two
runs (determinism confirmed: seeded keys + `now` pinned 1751500060, no EntropyProfile needed). Fixtures
`wormhole/Story/SwarmStaple/{toc,001–008}.snap` are UNCOMMITTED in the tree for the human to commit.

2026-07-04 pt 2: **SwarmWire** — the 2nd Book (beats 2-5): the SAME handshake as REAL Peeroleum frames.
`Swarm_deliver(w, ident, prepub, frame)` routes transport-first (my station `%Peering,name:<prepub>` → Pier
by pub → `Peeroleum_send({header:{type: frame.kind…}, swarm: frame})`; an unready link = unreachable, NEVER
falls to mail when a route exists) else the in-world mail; `Swarm_arm(w)` registers pier_hello|pier_accept|
pier_reject on the `w.c.on[type]` registry (additive frames, zero spine change; pre-Ud gate = swarm frames
cross only an authenticated link). Book reuses Lake_link with PREPUB station names + generic handshake
seeding (Lake_handshake hardcodes alice/bob). Headless 5/5 %see + deterministic; SwarmStaple re-verified
8/8 vs its live fixtures AFTER the deliver-seam change. SwarmWire live record still OWED. See
[[see-is-not-a-latch]] for the witness lesson it surfaced.

2026-07-04 pt 3: **SwarmSteal** — the 3rd Book (beats 2-6): §3's identity≠address split at the MODEL
layer. New `Swarm.g` *places* region: `Swarm_address` (session addr = `%Peering.sc.address`, defaults to
canonical `name`, → `<prepub>_N` after steal-back — name stays canonical so deliver-routing + byte-
identical export never move) / `Swarm_next_suffix(prepub, taken)` (next free `_N` past held) /
`Swarm_sibling`+`Swarm_is_sibling` (`%Sibling,place` roster = the Dexie-liveQuery "these-are-all-our-tabs"
set) / `Swarm_take_role` (`%Peering.sc.role` — tabs split music|encode for 6-hr-leak robustness) /
`Swarm_note_theft` (KNOWN sibling = cooperative, no alarm; else `%Peering.sc.stolen` + durable
`%Stolen,by/at` husk) / `Swarm_stolen` / `Swarm_steal_back` (concede bare name → next free suffix, clear
flag, husk stays as history). Swarm_protocol SESSION += `stolen,address,role`; skips += `Sibling,Stolen`
(all session-local, never exported). Book: Alice one key many places — beat 3 two sibling tabs (_1,_3) +
roles music|encode NO alarm, beat 4 foreign `remote_copy` → Stolen, beat 5 Steal Back → `_2` (past thief
+ _1 + _3), beat 6 key-never-moved proof. **Headless-green 5/5 + byte-deterministic** (2-run diff
identical modulo round=). WITNESS LESSON (owner-corrected — see [[see-is-not-a-latch]], now REWRITTEN):
my first cut made every %see PERSIST (read monotonic residue so it re-mints forever) — owner: "that's
silly, they drop for a reason." Fixed: each %see is GATED to its beat (`n === K`) reading LIVE truth, so
it appears once and DROPS (1 fresh claim per step, not an accumulating ledger — persistence = the old
%witnessed noise reborn). Also dropped `reached:step_N` from BOTH Books (pure accumulating snap noise;
it LOOKED like a churn heartbeat but was a RED HERRING) — the real timing knob is WHERE you seed: moved
SwarmWire's %req:handshake seed to beat 2 so "authenticated" lands deterministically at step 3, provable
BEFORE the beat-4 frames (at beat 3 it raced to step 4). BOTH **live-recorded green 2026-07-04**:
SwarmSteal 6/6 caveat:0; SwarmWire 5/5 with step-2 caveat:1 (its beat-2 handshake seed is mid-flight at
the step-2 snap → fuzz-tagged, run stays green — the EntropySamples pattern; assertions steps 3-5 clean).
Fixtures uncommitted for the human. Design came from the owner's multi-tab
vision: local Dexie siblings (cooperative, share Id w/ _N) vs a remote copy (real steal); to:$pub +
to:$role addressing STAYS; ties to BigWordland/Educarium reusing one editor id. Next: relay duplicate-
hello collision notice (today `to:<pub>` bind is silently ADDITIVE — the `@channel` "taken" refusal is
the template) + Dexie liveQuery wiring + the UI banner.
