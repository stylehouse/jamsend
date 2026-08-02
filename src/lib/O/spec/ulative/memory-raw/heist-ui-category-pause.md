---
name: heist-ui-category-pause
description: "2026-07-29 overnight Heist polish per the human's feedback: KeepFace category (was 'file under'/genre) as a `- name` sort-topward folder, nestable via `/`; TWO buttons nab-album/nab-track (Heist_keep_pick_seed added) replacing all/none; snaps-shut fixed (local $state, commit on blur); no music/Unfiled prepend + Heist_music_root test param; pause latch (radio.c.ever_played). All Book-green."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

The human's 2026-07-29 Heist feedback, actioned (all changes NOT committed; MusuHeist + Sounditron GREEN):

- **Category, not "file under".** KeepFace/KeepBarFace label is now "category". `Heist_keep_set_genre` stores a
   user category WITH a sort-topward prefix — `- <name>` (or `0 <name>`; a name already prefixed is kept
    verbatim) — the human "becomes a `- ${name}` folder ... `0 ${name}` too". EMPTY category clears it (no
     prepend). `Heist_cat_path` splits a category on `/` and safe-segs each level, so categories NEST
      (`0 chill/0 very chill`). ONLY the UI verb prefixes — MusuHeist pins genres via choices (bypasses
       set_genre) and its single-segment genre passes `Heist_cat_path` byte-identical, so no fixture drift.
- **No prepend by default** ([[heist no-prepend]] = the #37 work): `Heist_filing_for` returns '' (was 'misc'),
   `Heist_rel_for` drops the level when no category, `Heist_keep_filings` default '' (was 'Unfiled'). So an
    unfiled keep lands with the SOURCE folder structure intact under the music root. `Heist_music_root()` now
     honours `M.c.heist_root` (test-isolation param — the human "a param for a test or two to make them save
      somewhere isolated"); prod default stays 'music'.
- **Two buttons, not all/none.** The human "no options about all|none ... basically two buttons, nab the album
   or nab the track". `nab album` = Heist_keep_pick_all (keep every husk); `nab track` = NEW
    `Heist_keep_pick_seed` (keep ONLY the seed track — the husk whose `re`/id is the seed content-id).
- **Field snaps shut FIXED** (the human "reactivity_docs ... the field snaps shut, same as UI:Waft"): the
   category input's `value=` was driven by the per-trickle `face` $derived, so every H.version/tick bump reset
    it mid-type. Now a LOCAL `$state` catDraft (`bind:value`) with `$effect(() => { if (!catActive) catDraft =
     face.genre })` — re-seed from the model ONLY when not focused, commit on blur. The reactivity_docs
      "Liesui Waft/+Doc form closing" §. Applied to BOTH KeepFace + KeepBarFace.
- **Pause sticks** (the human "pause is not remaining after one think ... start-playing-on-startup disabled
   after one success"): `Radio_pump` sets `radio.c.ever_played=1` on the first real chunk feed; `Sounditron_listen`
    (the trickle-driven auto-start) early-returns if `ever_played` — so a deliberate pause is never re-pressed.
     Before the first success it still retries (a gestureless tab starts once audio/friend arrives). `.c` → a
      reload re-arms.
- **Now-playing** already shows `{artist}`/title (RadioFace); the Heist shows the source DIRECTORY structure
   (KeepFace's dir-grouped tree), which is what the human wanted there ("just say directory structure ... by default").

STILL OWED (needs the human live): the FULLSCREEN prototype configuring UI (`src/lib/O/Funk/HeistSetup.svelte`
 is ORPHANED — nothing raises it) rebuilt to the Peerily `Pirate.svelte` model (path broken into slash-separated
  places, a `nab` button on the album-dir place vs the track-blob place, per-segment category include/exclude
   toggles, per-segment existing-check). The prototype spec is fully captured (src/lib/mostly/Pirate.svelte +
    ghost/Pirating.svelte). See [[heist-pull-want-storm-fix]], [[vyto-nested-is-global-grapple]], [[mag]].
