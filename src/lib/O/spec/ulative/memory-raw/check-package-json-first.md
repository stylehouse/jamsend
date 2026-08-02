---
name: check-package-json-first
description: "Before hand-rolling any parser/codec/format code, read package.json — the human keeps libraries for this (\"didn't we have a library for that?\")"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 587585e3-e873-4c0a-926a-ee486cbe4df5
---

The human, on finding a hand-rolled RIFF/ID3 tag parser in Crate.g: "fuck, you're up to more low-leveling again... didn't we have a library for that? read package.json" — music-metadata@11 was ALREADY a dependency.

**Why:** hand-rolled format code duplicates shipped deps, is worse-tested, and burns review time. Known deps to remember: music-metadata (tag READING — it cannot write; a test-fixture tag WRITER stays hand-rolled), @noble/ed25519 (the @noble family also has streaming hashes), dexie, @lezer/*, diff-match-patch, needles (loudness).

**How to apply:** before any agent (or I) writes byte-level parsing, `grep package.json` first and prefer an IMPORT() of the dep (the .g-imports-ts pattern). Put this check in subagent briefs for format work.
