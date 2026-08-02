---
name: socklog-scaffold
description: "ALMOST-GONER diagnostic (KEPT by owner): browser relay-socket capture dumped via Wormhole + opt-in auto-reload — readable off /app; committed, don't rip"
metadata:
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

A browser-side observability scaffold (built 2026-07-01) that lets a headless session read the live relay socket traffic a human would see in DevTools → Network, without restarting the host dev server. Used to live-verify [[runs-broadcast-both-runners-fix]]. **Status: the roster/dispatch bug it chased is FIXED, host COMMITTED it, and the owner said KEEP it (marked ALMOST-GONER in-code) as close-up socket knowledge for future runner/relay debugging. Don't rip it out — it's dormant unless armed (`?watch=N`) and the tap is cheap. Grep `ALMOST-GONER` to find all three pieces.**

- `src/lib/O/sockcap.ts` — wraps the global `WebSocket` (constructor + send), scoped to `/relay` URLs, into a 5000-entry ring of `{t,dir,to,type,seq,from,len,line}` summaries (control:log keeps its `line` = the relay's routing narration). `SOCKCAP_BOOT` = one id per page life.
- Otro: `sockcap_install()` + the `&watch=<min>` auto-reload are BOTH **armed opt-in only** (2026-07-01 fix — owner caught the capture running on every plain tab, parking a full JSONL blob in an rw req every ~10s). The tap installs ONLY on `?socklog` (or implied by `?watch=N`); with no capture `Lies_dump_socklog` early-returns (`!sockcap_count()`), so a plain editor|runner tab writes nothing. Arm with `?socklog`, or the **🪪 Id (IdHatch) `socklog capture` toggle** → `socklog_arm()` writes `localStorage.socklog`, which `socklog_armed()` (sockcap.ts) reads at Otro boot. Toggle takes effect on the next reload (the tap must precede the socket open).
- `Lies_dump_socklog(w)` (LiesLies, driven in-think from `Lies_heartbeat`, ~10s throttle) writes the ring via the rw_queue→Wormhole rw_op to `wormhole/_socklog/<role>-<bootid>.jsonl` — one file per page life (so a reload preserves the prior life's log). gitignored.

**Why browser+Wormhole, not the relay**: the dev server runs on the HOST (172.17.0.1), not this container — can't restart it or read its /tmp. `/app` is shared, and `wormhole/` is already rewritten constantly by Story snaps WITHOUT triggering vite reloads, so dumping there is safe + readable from the container.

**To read**: `ls -t wormhole/_socklog/editor-*.jsonl | head -1`, grep for `"type":"(rungo|become_book)"` and check `to:` (a `<pub>` = individuated ✓, `runner` = broadcast). control:log `line` shows the relay's `→ <pub>/<runner> <type>` routing verbatim. Prune: `find wormhole/_socklog -mmin +30 -delete`.
