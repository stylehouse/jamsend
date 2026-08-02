---
name: no-advertise-param
description: Big*land end-user pages are machine-role runner but must NOT advertise — boot_qualand no_advertise:true gates Lies_advertise + Lies_going_cold
metadata: 
  node_type: memory
  type: project
  originSessionId: 587585e3-e873-4c0a-926a-ee486cbe4df5
---

2026-07-11: a /BigSoundland tab (sound → boot_role runner in boot_qualand) was beaconing
`Lies_advertise` and getting durably enrolled in the editor's registry as role:runner —
Story dispatches then land on someone's music page (it happened live: Chase runs ran on the
owner's BigSoundland tab, prepub 77d2…).

**Fix (owner-directed param):** `boot_qualand({book, role, no_advertise: true})` stamps
`h.c.no_advertise`; `Lies_advertise` AND `Lies_going_cold` (the raw ready:0 freeze beacon)
both bail on `H.top_House().c.no_advertise`. Both Big*land call sites pass it.

**Why:** one beacon is enough — `Lies_runner_roster` names every beacon-sender role:runner in
the durable Waft:Cluster/%HostedIdentity registry ("the directory is authority"; silence only
lapses grants, never un-names). So the cut must be at the EMIT.

**Consequence:** a no_advertise page is invisible to runner_ask/runner_shot (census = the
advertise). Voro live verification (📸 shots of the BigSoundland Cyto) needs a real ?B= runner
running the Book instead — see [[graph-of-music-scape]]. All other runner machinery (Creduler,
its own Book, relay channel) stays live on the page.
