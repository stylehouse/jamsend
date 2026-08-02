---
name: svelte-edit-bundle-proof
description: "After editing any .svelte, bundle-fetch it from the dev server for compile proof — runner gates never mount editor/panel components"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

A `<svelte:window>` placed inside an `{#if}` block shipped broken (svelte_meta_invalid_placement)
 and broke InvitePanel — and with it /BigSoundland — for several 600s soak cycles (2026-07-18).
  Every gate I ran was green because runner tabs never mount panel components.

**Why:** .g edits get LocalGen compile proof; .svelte edits got nothing — the live Book gates
 exercise the machine, not the page's component tree.

**How to apply:** after every .svelte edit, cheap compile proof:
 `node -e "fetch('http://172.17.0.1:9091/<path>.svelte').then(r=>r.text()).then(t=>console.log(t.includes('CompileError')))"`
  — the vite payload carries the error if there is one. Also: `<svelte:window>`/`<svelte:body>`
   must sit at template top level, never inside blocks.
