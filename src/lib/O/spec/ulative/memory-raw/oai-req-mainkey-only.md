---
name: oai-req-mainkey-only
description: "oai() triggers the %req machine when req is the MAINKEY, OR (since 2026-06-24) when req:1 the serialise-sentinel rides behind a real type (the typed serial-req flock, e.g. %Pier,pub,req) — but never on an incidental string req value-key"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 5d8fe287-52d7-4f12-86e7-52771961c866
---

`oai(s, c)` (Stuff.svelte.ts ~523) treats its target as a `%req` — running the req machine
 (serial, `c.up`, `initialdo`, mutate-on-rekey). The gate is now `Object.keys(s)[0] === 'req'
  || s.req === 1` (was just the first clause; originally `'req' in s`, which mis-fired on any
   incidental `req` value-key). Two ways to be a req:
- **MAINKEY req** — `%req:handshake` / anonymous `%req:1`. Classic; dispatched `req_<value>`.
- **TYPED serial-req** (added 2026-06-24) — a real type leads and `req:1` (the serialise
   sentinel) rides behind: `oai Pier,$pub,req` → `%Pier,pub:…,req:N`. The Pier flock. The mint
    spreads `{...s}` (NOT `{req:1,...s}`) so the type stays the mainkey; dispatched by **mainkey**
     (`req_Pier`) since the serial value can't name a method — see `do_fn_for` (Housing ~1131).

**Footgun still shut:** an incidental *string* value-key (`oai({lematch:1, req:'wants'})`) has
 `req !== 1`, so it's a plain particle, not a fake req — the bug behind EntropyArrest caps
  "vanishing" / `req:wants,lematch` rendering (see [[entropyarrest-spay-design]]). Audited
   2026-06-24: no existing particle carries a numeric `req:1` off-mainkey, so widening the gate
    corrupts nothing. A typed serial-req keeps its type queryable (`o Pier` variously) AND is a
     pumped req — "sublating req from being the headline type." Specs: Peeroleum_spec §6/§11.3,
      Hovercraft.design (dispatch ladder).

----
## merged from oai-only-at-canonical-spot.md

---
name: oai-only-at-canonical-spot
description: "reserve oai() for the one canonical \"starts-existing-here\" spot; reads use o()[0]"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: adc85dac-7c1b-4e93-b5ed-22e12fd629bc
---

Don't `oai()` liberally. `oai()` is find-or-create-**or-mutate-and-bump** (the post-consolidation
verb, ex `moai`), so a non-canonical `oai` is a *side-effecting read*: it can mint a particle as a
byproduct of reading, churn `%version`, pollute the snap, or crash a `$derived` (`bump_version` /
`i()` are forbidden mid-derivation).

**Why:** the `LE_clones` bug — it `oai`'d `{Seem:'working'}` just to read clones, inside a
NaviCado `$derived` → `state_unsafe_mutation`. The canonical creator was elsewhere (`LE_arm` →
`i_Seem`); `LE_pull`/`LE_add_clone`/`LE_encode_compare` were all consumers that should have read.

**How to apply:** use `oai()` ONLY at the single spot that owns a particle's existence (the
"starts-existing-here" creator/setup). Everywhere downstream that merely fetches it, use
`o(sc)[0]` (a read, no side effects) or `oa(sc)` for a presence check. A method that throws
"call X first" or otherwise assumes existence is a consumer — it must read, not `oai`. See
[[snap-inclusion-vs-pump]] and the `_foc` doc in Stuff.svelte.ts for the mutate/bump semantics.
