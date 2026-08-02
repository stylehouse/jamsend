---
name: rng-canonisation-sweep
description: "The 'canonise RNG so prod is fresh but tests are deterministic' sweep (human: 'just in Radios, and Vyto as well I suppose') is COMPLETE. Two genuine RNG streams, both handled: H.prng (shuffle meander) via Radio_prod_seed, w.c.prng (dial) via Ra_seed — both crypto-fresh in prod, Book-gated deterministic. Vyto has NO RNG (deterministic-by-construction, solver law 4) — nothing to canonise; a prod-seed would be WRONG. Tribunal jitter + editor hue deliberately left."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

The human's directive: seed the PRNG from crypto/timestamp in production so tracks/layouts vary per boot,
 but keep tests coming up with the same values. Asked "what instances of RNG need canonising with it?" →
  ruled **"just in Radios, and Vyto as well I suppose"** (tentative — so [[fight-back-on-core-changes]]
   applies: prove in isolation before forcing a change).

**The full sweep of the Radio/Vyto scope (2026-07-26):**

1. **H.prng — the shuffle meander** (`Housing.prandle`, read by `Crate_nav_meander`; default `[1,2,3,4]`,
    pinned for Books by `Musu_seed`). This is the real variety RNG. **`Radio_prod_seed(w)` (Radio.g, in
     `Stoker_ensure`)** fresh-seeds `H.prng` from `crypto.getRandomValues` at radio standup — GATED: a named
      Book run-world wears `w.sc.w`, so ONLY prod (no `w.sc.w`) reseeds; `H.c.prng_seeded` makes it one-shot.
       "prod" = **/BigSoundland** (the human's cut). LocalGen-clean; runner-verify OWED (spine ghost).
2. **w.c.prng — the dial** (`Ra_rand`, seeded by `Ra_seed`). **Already** crypto-fresh in prod
    (`Ra.g:~103`: `if (!w.c.prng) w.c.prng = [...crypto.getRandomValues(...)]`). No change needed.
3. **Vyto — NOTHING TO CANONISE.** `Vyto.g` has NO `Math.random(` call (the only "Math.random" hit is the
    `never Math.random — solver law 4` comment). `.c.seed` is **solver state**, not randomness: a newcomer
     enters at the frame-boundary point nearest the MEAN of existing seeds (frame centre 400,225 when first),
      then seed-and-relax steps toward area centroids — a deterministic function of (members, frame). Same
       inputs → same layout every boot. `vyto_geometry.ts` (power_cells/poly_centroid) + `Vytui.svelte` carry
        no RNG either. **A prod-fresh-seed here would VIOLATE solver law 4 and scramble the view on every
         reload** (bad UX; would also break any Book snapping Vyto anchors). Correct answer to "Vyto as well?"
          is **no** — it is already deterministic by design, which is what you want for a layout.

**Deliberately LEFT (out of the Radio/Vyto scope, correct as-is):** `Tribunal.g:~195` `Math.random()*300`
 reconnect-backoff jitter wants REAL entropy (anti-thundering-herd), never snapped/seeded. `stho.ts` +
  `lang.ts` editor-mount hue (`Math.floor(Math.random()*360)`) is cosmetic, not snapped — the human scoped
   it OUT. Cryptographic RNG (nonces/keygen — InvitePanel, cluster_trust) must NEVER be made deterministic.

So the sweep is done: the two genuine streams are both prod-fresh + test-deterministic; Vyto is a red
 herring (no RNG). See [[radio-pipeline-opus]], [[music-real-audio-pivot]].
