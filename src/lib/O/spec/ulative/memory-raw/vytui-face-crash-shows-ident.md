---
name: vytui-face-crash-shows-ident
description: "A \"bare Mainkey:value\" Vyto cell where a face is expected = the face is CRASHING, not un-faced"
metadata: 
  node_type: memory
  type: project
  originSessionId: 589b8f0b-32c5-427d-9aab-2e790bee64c1
---

Vytui mounts each faced cell inside a `<svelte:boundary>` whose `{#snippet failed(error)}`
 renders `<div class="face-err">{cell.ident}</div>` (Vytui.svelte ~590). `cell.ident` is
  `mainkey:value` (`ident_of`). So a cell showing the LITERAL text like `Keep:<album title>`
   where you expect a rich face is NOT an un-faced/generic cell — **the face component threw**
    and the boundary caught it. (The genuine no-face path — `face_of`→null — renders the same
     ident via a DIFFERENT branch `{#if !cell.face && !cell.hasKids}`, so the two look identical
      on screen; check the console for the boundary error to tell them apart.)

Concrete instance FIXED 2026-07-29: `KeepFace.svelte` called `safe(genre)` in its `face`
 `$derived` but the `safe` helper wasn't carried over when the face was split off `KeepBarFace`
  (which defines it) → `ReferenceError: safe is not defined` every mount → the human saw "just a
   bare-assed cell of Keep:$album-title" and "clicking ⇊ does nothing" (the cell was the crash
    fallback, so no working buttons). Fix = add the `safe` const to KeepFace. The driver spine
     (`Radio_keep`→`Heist_keep_beat`→`Heist_keep_step`→`Heist_keep_pull`) and every button method
      were all fine — it was purely the face crash. See [[heist-keep-chooser-built]],
       [[svelte-edit-bundle-proof]].

Tell for next time: bare `Mainkey:value` cell + a face IS registered for that mainkey
 (glass_faces `FACE_MAINKEYS`) ⇒ suspect a throw in the face's derive/script, not a wiring gap.
