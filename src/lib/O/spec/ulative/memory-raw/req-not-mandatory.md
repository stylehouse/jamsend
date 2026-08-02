---
name: req-not-mandatory
description: "req is a pattern for transient-move-trees, NOT a mandate for everything that 'thinks' — code and data can be separate"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4339ac5d-d2f6-4d4f-b39a-2cad0150dde4
---

You do NOT have to wrap every little thing "that thinks" in a `%req`. Code and data
 can be separate; req is just a pattern of **bundling/treeing** that pays off when you
  are hanging up LOTS of little transient moves that all want **finish / oncer /
   dependencies** on each other (the Peeroleum handshake leaves are the canonical case:
    said_hello→heard_hello→said_trust→heard_trust, each finishes, each gated by maz).

**Why:** req carries real machinery (supervision, finish, maz-ordering, ttlilt, the
 do() pump). That machinery is dead weight when the move is just "do this now, in order,
  done." MusuSkip is the proof — it decodes/skips/rebuilds (it "thinks") as PLAIN
   SYNCHRONOUS CODE in its drive (MusuSkip_seed/strike/rebuild), no req anywhere, and it
    is the cleanest of the seven Musu Books. Its Terminal/Player carry no `req` → passive.

**How to apply:** reach for `req` when you have a *tree* of transient moves with
 finish/oncer/dependency relationships between them. For a straight-line "compute then
  write" move, write code. The cascade migration ([[music-cluster-kickoff]]) made the
   Musu *spools* reqs because they re-arm and self-pump under the sweep — a real fit — but
    don't read that as "req everything." Counterweight to [[dsl-over-raw-js]]/[[g-over-scattered-ts]]:
     those say fold logic into the .g DSL, NOT that every move must be a req.
