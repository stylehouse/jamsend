---
name: glass-allowlist-inversion
description: "User glass = ALLOWLIST (use_faces worlds tuck every undressed cell-holder under 'system'); tuner lookup needs the H>A>w hop; CrateFace on Musu homes; gang mirrors label by member mainkey; stoker floors 24/8/20/44 + Stoker_mag_draw draw-Mags"
metadata: 
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

Built 2026-07-19 (uncommitted), the "remake the model going into VoroCyto" cut:

- **The inversion** (`cyto_crew`, Cyto.svelte): in a `use_faces` world (the user glass) any
  cell-holder with NO worn/imposed face, NO sc.crew, NO CREW_MAINKEYS entry crews `'system'`
  → tucked by the tuner's default `{system:1}` mute, still censused ("N tucked away").
  Non-faces worlds (Story glass, Voro Books) keep the old open floor — gated hard on
  `w.c.use_faces`, so no sealed fixture moves except via the Books that snap the voro model.
- **THE TUNER LOOKUP BOMB**: the Story rail commissions `Scannable = RunH` (the run House) and
  `client_w = w:Story` — the run world sits `H > A > w`, ONE HOP DEEPER than the o({w:1}) leg.
  Symptom: mute + census silently dead ("no crews yet", machinery never tucked, canvas node
  count never moves). The lookup now walks `o({A:1}).flatMap(o({w:1}))` too (Cyto.svelte ~379).
- **CrateFace** (`O/ui/CrateFace.svelte`, imposed via FACE_MAINKEYS MusuSelf|MusuThem→'Crate'):
  the record collection spread as little hue-hashed cards, ▶ = `Radio_tune`; husks dashed/dim.
- **Gang mirrors** label `{<member mainkey>: count}` ("req:7"), never `gang_of` (Cytui ~620).
- **Stoker supply for the 20-ahead lineup** (Radio.g): resurrect cap 24 · dig floor fresh<8 ·
  churn goal 20 · cull 44. `Stoker_mag_draw` — every churn that LANDS mints a `%Cloud` of
  `%Card`s on `radiostocking/%Mag` (cap 8 draws, oldest dropped) — the spec §2.3 culture trace.
  Stock stays FLAT by the human's own §2.4 ruling: Mags REFER by id, never contain.
- Sounditron's probe `%Heist` ("the one they played last night") mints `crew:'system'` — tucked
  in the user glass while real user Heists keep their face.
- **Ra_rand everywhere**: every `Math.random` in Radio.g (dial coin-flip, lineup pool pick,
  dial_pool pick, both riffle deals) now rides `Ra_rand(w, n)` — per-world xoshiro, crypto-lazy
  live default, `Ra_seed(w, str)` pins a Book, `Ra_entropy(w, vals)` stirs live feel in.
- **Sounditron fixtures CANNOT green by re-record**: the dominant non-determinism is DISK
  ACCUMULATION (each run's digs grow the radiostock the next run resurrects), not randomness —
  bless red-on-dige (assertion contract = the verdict) or exclude the stock set from its snap.
- **THE MAG PIVOT — PREENED 2026-07-19, the Mag direction WON**: the human ruled point-by-point into
  `spec/Mag_todo.md` (§1 naming/Berth storage, §4 wire wording + starvation legibility, §6 explode/
   octopus topic tree, §6b privacy = friend Mags never berth / Heist is the activated product, §8
    rulings incl. DURABLE oblique listen-history).  %Suggest mainkey RETIRES into one-card Mags
     (delivery pattern survives).  Flat stock (§2.4) is now the way-station; do NOT build new work on
      the flat %Tuner mute — the topic-limb attention mutex supersedes it.

**Why:** the human: "remake the model we're sending it… just the right stuff to show the user…
MUST FEEL LIKE SPREADING OUT YOUR RECORD COLLECTION ON YOUR BED."

**How to apply:** dress a particle for the user glass (face or deliberate crew) or it tucks;
verify tuck changes via `runner_shot` node counts, not the snap's Voronoiology rows (those are
world-side crusher output, crew-BLIND by design). See [[radio-brain-glass-faces]],
[[sounditron-wild-book]], [[live-share-wired]].
