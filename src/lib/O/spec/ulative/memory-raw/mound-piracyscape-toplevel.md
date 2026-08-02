---
name: mound-piracyscape-toplevel
description: "BigSoundland (lib/V/, was Mound) = the music/Piracy-scape toplevel, at the EXPLICIT /BigSoundland route. The bare / now 404s (bots hammer it → routes/+page.ts throws error(404); routes/+page.svelte is a dead fallback). PWA start_url moved /→/BigSoundland. old p2p/ghost Intro at /Intro"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5a75cfd5-1e53-4df0-a86a-d9f6d52ddc25
---

**UPDATE 2026-07-05:** Mound was renamed **BigSoundland** (`src/lib/V/BigSoundland.svelte`, [[bigqualand-aufheben]]) and the bare `/` route was **retired to a 404**: `src/routes/+page.ts` throws `error(404)` (an EXPECTED error — clean 404, no console spam per bot), and `src/routes/+page.svelte` is now just a dead fallback heading (kept for the route + the scaffold h1 unit test). BigSoundland lives at the **explicit `/BigSoundland` route** (was already wired as an "alias"; now the primary door), symmetric with `/BigWordland`. Reason: **bots hammer `/` constantly** and the owner didn't want the crawled root to be the app entry. The PWA manifest `start_url` moved `/`→`/BigSoundland` (`static/manifest.webmanifest`; `id`/`scope` stay `/` for stable identity + full-app scope) so an installed icon opens the scape, not the 404.

Historical (pre-update): `/` originally rendered Mound — the seed of the **Piracy-scape** toplevel, a Voro+Cyto UI. The old p2p + `lib/ghost` toplevel (`Intro`, `$lib/p2p/Intro.svelte`) was moved OFF `/` to `/Intro` (`src/routes/Intro/+page.svelte`) — relocated, not deleted, still reachable there.

Toplevel homes now: `O/Otro` → `/Otro`, `L/BigWordland` → `/BigWordland` ([[bigwordland-toplevel]]), `V/BigSoundland` → `/BigSoundland`, bare `/` → **404**. New Piracy-scape UI grows in `lib/V/`. Continues the futuristic-direction move away from `lib/mostly` ([[architecture-lib-mostly-legacy]]).

**BOMB — roles boot on `/Otro`, NOT `/`:** the editor/runner/idle role scheme (`?E=`/`?B=`/`?I=`/`?A=`, read by `boot_param` in Otro.svelte) only stands up when Otro mounts, i.e. the `/Otro` route. `/` (Mound, was Intro) boots no role — the old Intro at `/` was just the legacy p2p music page, never a role-booter. So a runner/editor URL is `/Otro?B=…` / `/Otro?E=…` / `/Otro?I=…`. Fixed 2026-07-05: `dockers/flock/bot.js` had opened root `/?I=<tag>` (wrong → showed Mound, booted nothing) — now `/Otro?I=<tag>&remoteWormhole=1`, keeping the stable per-bot tag (RESUMES the same identity across self-heal; a bare `?I=new` re-mints every crash). If you ever add a role param to a URL, remember it must sit on `/Otro`.
