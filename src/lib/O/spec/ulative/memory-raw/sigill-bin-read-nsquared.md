---
name: sigill-bin-read-nsquared
description: "a browser-tab SIGILL mid-playback = V8 fatal CHECK (usually OOM, compiled to ud2); root cause was Housing bin_read/read_file O(N²) chunk-concat — file-read concat MUST be linear"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

2026-07-28: the whole BigSoundland page died with **SIGILL after 17–21s of playback**. Root cause:
 `Housing.svelte.ts` `read_file`/`bin_read` joined a file's reader chunks with
  `chunks.reduce((a,b)=>{ const o=new Uint8Array(a.byteLength+b.byteLength); o.set(a); o.set(b,…); return o.buffer })`
   — which **reallocates AND recopies the entire accumulated buffer on every chunk = O(N²)**. A multi-MB
    track arriving in many small reader chunks recopied tens of GB, burned ~12s of `o.set()` (visible in a
     live Performance profile as `o.set` in `bin_read`), and OOM-fatalled the renderer.

Two durable lessons:
- **A browser SIGILL is a V8 fatal `CHECK`/OOM**, not a segfault — V8 compiles CHECK/UNREACHABLE to a `ud2`
   (illegal instruction). So "SIGILL mid-something" ⇒ suspect a runaway allocation / heap exhaustion, and
    profile for the hot allocator (here `o.set`), not a crash in native code.
- **Any file-read (or byte) concat MUST be a single linear pass**: sum sizes → allocate once → copy each
   chunk at a running offset. The fix is `concat_chunks(chunks)` at module scope in `Housing.svelte.ts`.
    `WormholeOpfs.bin_read` was already fine (`file.arrayBuffer()` in one native call). This O(N²)-reduce
     pattern is a recurring smell — grep `reduce((a, b)` near `new Uint8Array(a.byteLength + b.byteLength)`.

The same main-thread freeze also read as "the UI lost the track / pause won't click" — the audio thread
 kept playing while the main thread was blocked in the copy. Relates to [[running-check-in-container]].
