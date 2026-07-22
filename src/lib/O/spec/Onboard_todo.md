# Onboard_todo.md — first-run identity, open-share, and the BigSoundland welcome

The one living doc for the first-run funnel (commissioned 2026-07-22). When a NEW `%Identity`
 arrives — brought by an invite OR stumbling onto the webapp cold — a friendly speech-bubble UX
  should: solicit a **username**, offer **open-share** (with a hard "no sharing without FSA → use
   Chrome" warning), and offer to **join someone**. BigSoundland should treat first-timers nicely by
    REFRAMING the raw FSA permission prompt (the "FaceSucker" that Auto fires) into that bubble,
     invite-or-not. The invite-accept screen becomes the universal first-run place.

**Posture: this is a DISPLAY job (Vyto's zone, [[vyto-refactor-avoid-display]]).** The pieces already
 exist as Svelte; the work is orchestration + copy, not new wire. This doc is a SEAM MAP + handoff so
  Vyto isn't re-deriving it, plus the one thin wire contract that would help the UI. I do not touch the
   UI myself.

---

## 0. Get on with next

The recon (2026-07-22) found the funnel is ~80% already built as components — the job is to make the
 new-here flow UNIVERSAL (fire invite-or-not) and fold in open-share + the FSA/Chrome warning. Order:
1. **(Vyto)** Make `InvitePanel`'s new-here flow (`namer` + "✨ you are new here") fire on a cold arrival,
    not only on an `?Iz` invite landing — driven off a first-run state, not off invite-presence.
2. **(Vyto)** Fold the open-share offer + "no sharing without FSA → use Chrome" warning into that same
    bubble, reading the `compat_mode` capability flag.
3. **(Vyto)** Reframe the `BootGate`/`FaceSucker` first-FSA prompt on BigSoundland so it reads as the
    same friendly bubble, not a bare hoister.
4. **(me, if wanted)** The thin wire contract below — a first-run "needs-onboarding" state + a clean
    capability read — so the bubble renders STATE instead of sniffing conditions inline.

---

## The arc

Nothing new needs minting for the happy path — the identity, the username store, the FSA gate, and the
 Chrome detection all exist. What's missing is (a) the trigger to run the welcome on a COLD first run,
  not just an invite landing, and (b) one bubble that carries all three offers (name / share / join)
   with the FSA caveat, wrapping the currently-bare FSA prompt. That's presentation glue.

---

## What already exists (recon map — don't rebuild; verify line #s on contact)

**The cold first-run mint** (`src/lib/O/Auto.svelte`, WIRE on the House/C model):
- `Clustation_ensure_default` (~:309) — "this page always has an identity"; `/BigSoundland` is always the
   `'sound'` role identity, minted/resumed by role. This is the COLD-arrival mint (no invite).
- `Clustation_ensure_identity` (~:115) resolves `?I=` (`?I=new` mints, `?I=<tag>` resumes, absent ⇒ inert).

**The username store** (WIRE): `Clustation_friendly(name)` (`Auto.svelte` ~:190) stamps `friendly` on
 `%Identity`+`%Peering`, persists via `thang_put`. `cluster_name(prepub)` (`src/lib/cluster_name.ts:23`)
  is the deterministic default nick before a friendly is chosen.

**The username-ask UI** (DISPLAY, `src/lib/O/ui/InvitePanel.svelte`): the `namer` snippet (~:250),
 `name_save` → `Clustation_friendly` (~:157), "what do friends call you?" (~:273), "✨ you are new here"
  (~:292). Also the join door: `?Iz` landing verify + `join()` → `Swarm_redeem`, born-today auto-join,
   `?Iz`→`?I=<prepub>` swap. **This is the existing speech-bubble-shaped seam — grow the welcome here.**

**The FSA gate / FaceSucker** (DISPLAY over WIRE):
- `src/lib/O/ui/BootGate.svelte` — renders the FaceSucker ("one tap to open the music", ~:92) when
   `H.c.disk_gated` or an audio demand; `open_share()` (~:67) fires the FSA folder picker + AC resume
    inside the click gesture. `proactive` mode for music toplevels.
- `src/lib/p2p/ui/FaceSucker.svelte` — the fullscreen hoister SHELL; copy comes from BootGate's snippet.
   THIS is the "FaceSucker" the human named.
- `H.c.disk_gated` raised/cleared in `src/lib/O/Housing.svelte.ts` (~:1799 clear on real share, ~:1829
   raise under `?E=`/`?B=` where OPFS-from-github is illegal); the raw FSA call is
    `requestDirectoryAccess()` → `window.showDirectoryPicker` (`src/lib/p2p/ftp/Directory.svelte.ts` ~:445).

**The "use Chrome" seam** (DISPLAY): `src/lib/p2p/ftp/Shares.svelte:22` —
 `compat_mode = !('showDirectoryPicker' in window)`. The warning belongs beside this flag.

**BigSoundland wiring** (`src/lib/V/BigSoundland.svelte`, DISPLAY): boots via `boot_qualand({role:'sound'})`
 (~:41); already mounts `<BootGate proactive audio_fullscreen>` (~:164) and `<InvitePanel>` (~:197). Both
  reframe points are already on the page — this is why the job is orchestration, not plumbing.

**Red herring:** `SurprisePopover.svelte` is an IDE editor artifact, NOT onboarding — do not attach the
 welcome bubble there.

---

## The thin wire contract (mine, if the human wants it)

To keep the bubble rendering STATE rather than sniffing conditions inline, the wire side could expose:
- a first-run **`needs_onboarding`** read on the active identity (true until a `friendly` has been chosen
   AND the share/decline choice has been made) — so the bubble's steps are data, not `if`-soup;
- an **open-share decision fact** stored on `%Identity`/`%Peering` (chose-to-share / declined / unsupported)
   — a durable scalar, `1`-or-absent per the boolean rule, so "already answered" survives reload;
- the **capability** (`compat_mode`) surfaced as a read the bubble consumes, so the "use Chrome" warning
   and the share offer are the same source of truth.
None of this is required for Vyto to build the UI against the existing hooks — it's ergonomics. Build only
 on the human's say-so; otherwise the UI can read the existing `friendly`/`disk_gated`/`compat_mode` directly.

---

## HUMAN decision

How far do I go on this? RECOMMEND: I write **only the thin wire contract above** (if you even want it),
 and hand the whole UI job to Vyto with this map. The alternative — I touch `InvitePanel`/`BootGate`/
  BigSoundland myself — collides with the display refactor and I'd advise against it. Say the word if you
   want the wire contract built; otherwise this stays a handoff.
