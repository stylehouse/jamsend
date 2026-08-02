---
name: grep-binary-spec-docs
description: spec/handover .md files hold UTF-8 punctuation; plain grep treats them as binary and silently finds nothing — use grep -a
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9a795549-13bb-48f6-aefa-25d437be5ae5
---

The spec docs under `src/lib/O/spec/` (e.g. `Peeroleum_handover.md`, `Hovercraft.design.md`) are full of UTF-8 punctuation — `·` middot, `—` em-dash, `…`, `§`. Plain `grep` flags such a file as binary and prints nothing (or "Binary file matches"), so a search for text you can plainly see in the file returns empty and looks like the string isn't there. Use `grep -a` (force text mode) on these files. Cost a few wasted tool-calls before I spotted it; `grep -anE "^#"` for headings, etc.
