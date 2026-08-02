---
name: delete-sc-key-query-safe
description: "removing one sc flag-key from a particle — `delete n.sc.key` is query+snap safe despite the stale X index"
metadata: 
  node_type: memory
  type: reference
  originSessionId: f89054ac-2b6d-4cf8-bef5-55222eab62a2
---

To remove a single scalar key from an existing particle (e.g. drop a transient `%queued`/`%handling` flag while accreting a state walk), use plain `delete n.sc.key` (then `n.bump()` for reactivity). There is no DSL verb for this yet (heading L lists `drop`/`empty`/`oa` as gaps); `host.r({k:1},{})` removes whole *children*, and `host.drop(child)` hides a child — neither unsets one key on a particle.

**Why it's safe even though the X index goes stale:** `o({key:1})` first hits the index (`q.X.o_kv`) which still lists `n` after the delete, but the post-filter `n_matches_kv` checks `n.sc.hasOwnProperty(key)` (`Stuff.svelte.ts:422`) and rejects it. The encoder/snap walks `n.sc` directly, so the dropped key vanishes from the snap too. So a JS-side `u.sc.flag` read and an `o({flag:1})` query agree after the delete.

First used in Peeroleum heading 4's serial inbox (`Peeroleum_pump_inbox`): `%unemit` walks `queued→handling→verified→done`, dropping `queued`+`handling` at `done` so the terminal is a clean `verified,done` and the serial-lock query `some(handling && !done)` stays correct. See [[peeroleum-bootstrap]], [[o-query-wildcards-on-1]].
