---
name: o-query-wildcards-on-1
description: "C.o({key:1}) wildcards on VALUE — numeric 1 matches any value for that key; use exactly() or a string for an exact match"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 557fc40b-0683-43b9-930d-d72d44800f5e
---

`C.o({key:1})` matches any child that HAS `key`, regardless of its value — a numeric
`1` is the wildcard (`Stuff.svelte.ts` `n_matches_kv`: `if (value == 1 && typeof
value == 'number') return true`). So `o({Interest:1})` matches `{Interest:'Trail'}`,
`{Interest:'Ting'}`, etc., and `o({req:1})` matches every req type.

For an exact match on value `1`, use `o(exactly({key:1}))` (the `exactly` helper from
`Y.svelte`; stringifies 1 to "1"). For any other exact value, a string already matches
exactly (`n.sc[key] == value`).

**Why care:** this wildcarding caused two real bugs — `LiesStore_write`'s dige-dedup
`o({req:1,path})` matched its own caller `req:LiesStore_writeCarefully` (same path+dige)
and silently dropped source writes; and promoting `{Interest:1}`→`{Interest:'Trail'}`
meant every `o({Interest:1})[0]` reader could grab the wrong Interest once kinds coexist.
When promoting a value-1 particle to a typed value, audit every `o({key:1})` reader.
See [[interest-channel-graduated]].

**A MAINKEY-LESS query returns NOTHING (proven live 2026-07-14).** `o()` buckets children by the query's
FIRST key treated as the MAINKEY. So `jam.o({at:1})` — where `at` is a NON-mainkey property (the events are
`%Spin`/`%Like`/`%Grab`) — finds no bucket and returns `[]`, even though every child HAS `at`. To gather
across distinct mainkeys, ENUMERATE the mainkeys (`for (const k of ['Spin','Like','Grab']) jam.o({[k]:1})`)
then sort — do NOT rely on a shared non-mainkey property as the query. This bit `Jam_ledger` (the ledger
came back empty, `events=0`) AND an adversarial static reviewer asserted the opposite (it CANNOT be caught
without a live run). The runner gate earns its keep on exactly this class of bug.
