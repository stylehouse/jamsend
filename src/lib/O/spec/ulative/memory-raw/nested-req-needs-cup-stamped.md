---
name: nested-req-needs-cup-stamped
description: A %req hosted below w (under a domain particle) silently never pumps unless c.up is stamped — the walk only wires A/w
metadata: 
  node_type: memory
  type: project
  originSessionId: c1f1d0c0-bfab-40d0-b3a2-8bdf30ef2871
---

A `%req` hosted on a domain particle *below* `w` (e.g. `w/Peering/Pier/%req:handshake`) will **silently never run** unless the host chain's `c.up` is stamped by hand.

**Why:** `host.do()` → `_req_do_one` resolves the do_fn by climbing `host.c.up` until it finds a House with `do_fn_for`, then calls `this['req_<name>']`. The belief walk wires `A.c.up` (`Housing.svelte.ts ~992`) and `w.c.up` (`~1021`) but **nothing wires domain particles under w** (Peering/Pier/plain containers). So the climb from such a host hits `undefined` immediately → no handler → the req stays `needs_work` and is skipped. **No throw, no warn.**

**Symptom:** the req particle stands up in the snap (the `oai` created it) but has **no children/leaves and no error** — the do_fn body (which would seed leaves / write particles) never executed. Down-walks (`w.o({Peering})[0].o({Pier})[0]`) still work, so a feature that only ever reads downward (e.g. frame delivery) won't reveal it — only pumping a nested req does.

**Two tiers, don't conflate them:**
- **A/w tier:** a freshly-laid `A:`/`w:` gets `c.up` only once a *later* `beliefs()` pass processes it (the rule of thumb "create A/w in one beliefs() before using them in anything"). So lay sides a step before you pump them and the walk wires `A.c.up`/`w.c.up` for free.
- **Below-w tier:** the walk wires `A` and `w` and STOPS — it never descends into domain particles (Peering/Pier/containers), so their `c.up` is *never* auto-wired no matter how many passes run. These you stamp by hand.

**Fix (the migration idiom):** stamp the host chain when you create it — `Peering.c.up = w; Pier.c.up = Peering` — raw JS (objects on `.c`). Cf `examining.c.up = w` (Lies.svelte:591), `funks.c.up = w` (LiesEnd.svelte:619). Note `req.oai/doai` DO set `req.c.up = host` (Stuff.svelte.ts:551) for a **`req`-MAINKEY** req, so the **req tree itself** is fine; it's the **non-req host chain** the walk leaves unwired. **CAVEAT (PereStaple swarm, observed by behaviour — [[peeroleum-swarm-refactor]]):** a **TYPED serial-req** (`Pier`/`Peering` mainkey + `req:1` sentinel) created via `oai` did NOT have `c.up` wired at SETUP time — reading `pier.c.up` immediately (before its first pump) was `undefined` and threw. So hand-stamp typed serial-reqs too (`peering.c.up=w; pier.c.up=peering`) whenever you read `.c.up` before a pump (e.g. carrier-pairing at link setup). Hit in Peeroleum heading 3 ([[peeroleum-bootstrap]]); related [[reqy-deleted-c-native]].
