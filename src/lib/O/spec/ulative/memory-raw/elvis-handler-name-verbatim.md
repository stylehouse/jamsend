---
name: elvis-handler-name-verbatim
description: "i_elvisto(target, name) dispatches to handler e_<name> verbatim — the elvis name must equal the handler minus e_"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c60bfb9d-149f-44b1-82ae-ac208dab6e3e
---

`i_elvisto(target, name, extra)` resolves the handler as `(House)['e_' + name]` verbatim
(Housing.svelte ~1047: `const handler = (this as any)['e_' + elvis]`; on miss it only
`console.warn`s `no handler e_${elvis}` and silently does nothing — no throw).

So the elvis **name must equal the handler name minus the `e_`**, including any ghost prefix:
- handler `e_Lies_open_Waft` ← call `i_elvisto('Lies/Lies', 'Lies_open_Waft', …)` / Plan `e:Lies_open_Waft`
- handler `e_Lang_foreground` ← call `'Lang_foreground'`  (NOT `'foreground'`)
- handler `e_mark`            ← call `'mark'`

This bit me: I named handlers `e_Lang_foreground` / `e_Lies_open_sidetrack` etc. but called them
as `'foreground'` / `'open_sidetrack'` (and Plan `e:foreground`). They silently no-op'd — "nothing
happens most of the time" in the Story snap; only the correctly-named ones (`e:Lies_close_Waft`,
`e:mark`) fired. There are both prefixed (`e_Lies_*`) and bare (`e_mark`) handlers in the codebase;
pick one and make the call site match exactly. Related: [[story-step-lines-drive-steps]], [[interest-channel-graduated]].
