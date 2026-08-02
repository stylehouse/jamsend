---
name: cluster-identity-nick
description: cluster identities wear a deterministic cosmetic nick (cluster_name(prepub)); COSMETIC ONLY — never route/store/trust on it
metadata: 
  node_type: memory
  type: project
  originSessionId: 5a75cfd5-1e53-4df0-a86a-d9f6d52ddc25
---

Built 2026-07-05: `src/lib/cluster_name.ts` exports `cluster_name(prepub)` — a PURE, deterministic adjective-noun handle (e.g. `copper-otter`) folded from all 16 hex digits of a prepub (32×32=1024 combos, jamsend-themed word lists). Same pub → same name, and any peer can name any pub it sees WITHOUT the name being stored/advertised/agreed. `Clustation_concrete` (Auto.svelte) stamps `ident.sc.nick = cluster_name(prepub)` at every mint|adopt; `Clustation_self` returns `{prepub, nick}`; IdHatch shows `active: <nick> · addr <prepub>…`.

**Why / how to apply:** the cluster network is PRIVATE, so a human handle needn't be unique or cryptographic — but it is **COSMETIC ONLY**. The prepub stays the real address + verification key everywhere that matters (to:<pub> routing, signing, the %Peering `name`); NEVER key storage, routing, or trust off the nick, and don't plumb it over the wire (it's derivable). Collisions are possible + harmless (prepub disambiguates). This deliberately RE-ADDS the friendly label Auto.svelte:97 had dropped as "dead weight" — the owner reversed that call; chosen shape was "cosmetic label" over "name as the ?I= handle" (don't promote it to the handle without asking). Relates to [[clustation-identity-layer]], [[cluster-trust]].
