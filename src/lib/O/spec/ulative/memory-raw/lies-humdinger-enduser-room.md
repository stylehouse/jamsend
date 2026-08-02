---
name: lies-humdinger-enduser-room
description: "Lies%humdinger = end-user Big*land room on the full Lies stack but INVISIBLE to editor's grid; ping-`from` was the roster-enrollment leak"
metadata: 
  node_type: memory
  type: project
  originSessionId: 75a40f34-e33a-4d31-a65c-a22dcd8f7f5d
---

`Lies%humdinger` (H.c.humdinger, snapped on w:Lies) marks an END-USER Big*land page — /BigSoundland (role sound→machine runner), /BigWordland (role word→machine editor). Derived from role in `boot_qualand` (BigQualand.svelte.ts) so no call site forgets it; replaced the old `no_advertise` opt. Uses the FULL Lies stack (relay channel, Creduler gen, remoteWormhole, Peeroleum music, its own Account) but speaks NONE of the editor-coordination presence protocol.

**Why:** BigSoundland kept appearing as a dispatch target in the editor's roster → Story runs landed on someone's music page. The `no_advertise` flag guarded `Lies_advertise`/`Lies_going_cold` but MISSED the real leak: the 5s `Lies_ping` stamps `from:<prepub>` for a machine-runner, and editor-side `Lies_pong` MINTS a roster beacon from a ping's `from` alone ("minimal ready beacon if first-heard"), which `Lies_runner_roster` then folds into the durable Waft:Cluster/%HostedIdentity registry. So the page re-enrolled every 5s regardless of the advertise gate.

**How to apply:** `Lies_humdinger(w)` in LiesLies.svelte is the whole gate. It (1) skips `Lies_advertise`, (2) skips `Lies_going_cold`, (3) strips `from` from `Lies_ping` (the actual fix — no `from` ⇒ no roster mint). Keepalive/watchdog LEFT ON so reconnection still works (from-less ping like an editor's; onclose re-dials; relay terminates half-open). Real ?E=/?B= machines have no id_role ⇒ no humdinger ⇒ grid protocol untouched. Residue: a stale anonymous `HostedIdentity,role:runner` (no favourite_client) self-GCs via Lies_runner_roster's silent-anon forget path. Open follow-up: the WORD room is machine-EDITOR and could still act as a dispatch coordinator — humdinger doesn't yet address the two-editors/coordinator question. See [[mound-piracyscape-toplevel]], [[roles-divide-addresses-deliver]], [[gen-crosswire-runner-dead]].
