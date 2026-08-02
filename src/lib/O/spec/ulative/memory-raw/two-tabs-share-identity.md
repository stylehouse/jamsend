---
name: two-tabs-share-identity
description: Why two same-origin tabs are the SAME Pier (role-default identity shared via Dexie) — presence looks fake; fork distinct Piers with ?I=new; InvitePanel now has rename-anytime + identity switcher
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**The gotcha (bit the human 2026-07-27, testing presence on one machine).** Two tabs of a
 role-default page (`/BigSoundland`, `/BigWordland` — anything booting with NO `?I=`) are the
  **SAME Pier**, showing the identical identity (e.g. "🚪 Righto · 56fbce44"). Cause:
   `Clustation_ensure_default` (Auto.svelte ~L300) RESUMES "the `sound` identity" stored in Dexie
    under the ROLE key (`sound`/`word`/`runner`/`editor`). Two tabs = same browser = same Dexie =
     both resume the one role identity. So **"is the other Pier online?" has nothing to point at**
      — presence isn't broken, there's no distinct pub. DoorFace's liveness dot needs a DIFFERENT
       pub to light; a friend of *yourself* can't exist.

**The fix / test recipe — fork a distinct Pier with `?I=`.** `?I=new` mints a fresh identity and
 rewrites the URL to `?I=<prepub>` (Auto.svelte ~L129-149, [[clustation-identity-layer]]); `?I=<prepub>`
  resumes a specific one; `?I=` WINS over role-default (Auto.svelte:471 before :484). So to run **two
   real Piers on one machine**: tab A = role default, tab B = open with `?I=new`. Then seal them
    (invite QR / paste-link) and presence + sharing are testable over loopback→relay. This is the
     cheap rehearsal of the "one gate" ([[jamsend-state-survey]], Frontier.md §1).

**BUILT 2026-07-27 — the Invite panel drives it (per the human's ask "change name / see which
 Identity / switch / URL &I=").** `InvitePanel.svelte`: (1) **rename anytime** — an always-on ✎ next to
  the name (was latched behind first-time onboarding), calls `Clustation_friendly`; (2) **shows which
   identity** — nick/friendly + prepub8; (3) **switcher** — `↪` chips per other stored identity +
    `＋ new identity`, each `go_identity(tag)` = `location.assign` with `?I=<prepub|new>` (preserves
     `?B=…`, drops stale `?Iz`; a full RELOAD, since identity resolves at boot). New read-only verb
      **`Clustation_roster()`** (Auto.svelte, beside `Clustation_self`) enumerates the identities
       Thangs container, deduped per prepub (a rename stores the same key under BOTH prepub + role
        tags), PUBLIC bits only. Both files bundle-proofed HTTP 200. **NEW verb → hard-reload the runner
         tab** (HMR won't re-run the identity eatfunc). The DoorFace ✎ (🚪 glass cell) already called
          the same verb; the panel is the sure fix. See [[verify-via-live-runner]], [[svelte-edit-bundle-proof]].
