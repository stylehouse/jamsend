---
name: toc-collapse-orphaned-save
description: "An orphaned/reloaded run's story_save can REWRITE a Book's toc.snap down to a 1-step skeleton (Styles emptied, Opt flags dropped, step lines gone) — check toc line count before trusting a dispatch; restore from git"
metadata: 
  node_type: memory
  type: project
  originSessionId: f4eec47c-5092-4a7d-a304-39f88375f249
---

**A run that boots against a barely-started `The` saves it back over the real toc.** Seen 2026-07-04 on MusuReplica: after a flock-tab reload orphaned a run, the working-tree toc.snap had collapsed from 85 lines (full Styles palette, waitCyto/useCyto/dontSnapCyto, 14 step lines) to a 15-line skeleton with ONE `step,dige:` line — so the next dispatch ran 1 step, red, total=1.

**Why:** story_save encodes the live `The**`; an orphaned/fresh session whose The never fully decoded (or decoded pre-crash) writes that stub to disk. The committed toc is the recovery source.

**How to apply:** when a Book suddenly runs with the wrong `total` or its opts don't take, `git diff wormhole/Story/<Book>/toc.snap` FIRST — if collapsed, `git checkout --` it, re-apply intended edits, re-dispatch (become_book re-reads disk). Related: [[host-commits-midsession]], [[runner-wedge-begun]], [[story-step-lines-drive-steps]].

**The NEW-Book variant (2026-07-07, VoroRadio):** a runner booted BEFORE the Book's dir existed has it invisible in its cached wormhole listing → first dispatch decodes not_found → runs a 1-step fresh skeleton (green bubble, total=1) AND story_saves that skeleton OVER your authored toc. The toc is UNTRACKED (new Book) so git can't restore — rewrite it from your authoring. The clobbering save itself seeds the runner's listing, so restore-toc + re-dispatch works WITHOUT a tab reload (VoroRadio read 9 steps on the second dispatch).

----
## merged from toc-clobber-expand-race.md

---
name: toc-clobber-expand-race
description: "wormhole/Story/*/toc.snap reset to Step-less skeletons — DirectoryListing.expand clear-then-refill race → read_file false not_found → Story 'new' mode re-records over the fixture; FIXED 3 layers 2026-07-04"
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

**The toc.snap clobber (found+fixed 2026-07-04).**  LeafJuggle + LakeTiles fixtures were
 overwritten by Step-less skeleton tocs (Styles/Plan/Opt/TimeSpool, fresh step dige, 001.snap
  re-recorded) during a `&disk=proxy` runner session.

**Why:** the chain was (1) `DirectoryListing.expand()` (p2p/ftp/Directory.svelte.ts) CLEARED
 `files`/`directories` then refilled across an await-per-entry — the banned empty-intermediate;
  the editor serves several runners' wh ops concurrently against SHARED DL objects, and the
   serve `list` op re-expands every time, so a concurrent `read` lands mid-expand → (2)
    `WormholeNav.read_file` → null → `{not_found, toc_snap:''}` → (3) Story's toc load took
     `reply?.toc_snap ?? ''` — error/not_found indistinguishable from a NEW Book → decode('')
      → `mode:'new'` → the run records itself green → story_save writes the skeleton over the
       fixture.  Credulate also stamps a bogus `last_ok`.

**Why (fixed, 3 layers):** expand() now builds ASIDE and assigns once (swap-don't-clear;
 child DLs reused by name so WormholeNav._cache identity holds); read_file re-lists ONCE on a
  miss before answering not_found (a stale listing predating the file is otherwise a
   permanent false no); Story's toc load treats `reply.error` as retry-forever-loudly and
    confirms a `not_found` with one re-ask before accepting new-Book status.

**How to apply:** never let a read failure default into "the thing is empty" when an empty
 read arms a WRITE — the failure default must be inert.  Forensics that worked: mtime
  clustering (`ls --time-style=full-iso`), and [[socklog-scaffold]] captures — a wormhole_reply
   of len≈137 is `{not_found}` where real toc content is ≈2.2k; become_book frames time-locate
    which runner ran what.  Class-instance edits (WormholeNav/DirectoryListing) need tab
     RELOADS, not HMR — navs hold constructed objects.  See [[remotewormhole-mutex-deadlock]],
      [[verify-via-live-runner]].
