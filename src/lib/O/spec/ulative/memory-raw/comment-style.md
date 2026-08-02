---
name: comment-style
description: how the user wants code comments written
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fa0ec816-b234-47f2-acb4-2627d6da2daf
---

Code comments must be "eternal" and self-contained: describe what the code does and why,
in plain prose, so they stay true on their own.

**Why:** the design docs (e.g. Hovercraft.design.md) are explicitly not well-preened and their
sections age out — a comment pointing at "§5a" or "TODO 4" rots. Be precise with terminology:
don't import a doc's loose shorthand into code (e.g. calling roai's behaviour "the r preset"
reads as the `r()` method — say "replace" plainly).

**How to apply:** no design-doc section markers (§N) or TODO-number references in comments;
match the surrounding prose style; use house notation (%req, /like,this) where it helps; name
things by what they actually are. See [[running-check-in-container]] for verifying edits.

**`|` is "or"; `/` is inside-ness — everywhere, including prose to the user.** Alternation uses `|`
(`canonical|stored`, `editor|runner`, `read|compile|include`), NEVER `/` — in this language `/` means
host-of|inside-ness (`dock/%Map`, `and/like,this`), so `this/that` misreads as "this inside that". I
keep erring on this in chat; hold to it in every reply, not just code. (NOTATION.md §"`|` and `/`".)

**Indent is the BRANCH — a comment's indent stack is a parse tree of the thought, never line-wrap.**
The leading-space depth after `//` encodes a fork: a line indented one level deeper than the line
directly above is **subordinate to, or a consequence of, it** (the gotcha/dependency that hangs off
the parent — the user's words: "a definite forking sentence relativity structure based on that stack
of indent"). Siblings align at the same depth; pop back out to resume a higher point. Every line is
its own crisp one-line meaning —
  NEVER a +1-space-per-wrapped-line staircase (the "wandery" smell)
  and don't mark the branch (no `↳`); the indent already says it.
The human RE-FLAGGED this 2026-07-12: "the indentation is a MEANINGFUL STACK, not just slanting a
 huge word wrappage" — after I grafted a block that slant-wrapped one paragraph ever-deeper. That IS
  the anti-pattern. Also: **the FIRST line is a fairly complete high-level idea of the whole block —
   NOT the symbol's name restated** ("it's right there"). Depth-1 lines are the sub-topics; depth-2
    their details. Began converting the code I touch to this; "we'll get around to changing them all
     one day" — sweep opportunistically, don't restate the name, lead with the idea.

**Markers:** `// <` = a **lack of development** — a deferred gap, a thing not yet built. `→` = **inline
flow**, "leads to" left-to-right on one line (`compile → settle → run`) — the horizontal twin of the
vertical indent-fork. Canonical source: NOTATION.md "## Comments" (keep that and this in sync).

**VOLUME — I run grossly overcommenty; cut hard.** (User, 2026-06-27: "you're being grossly
overcommenty lately.") `compile.ts` hit **36% comment lines** built up over recent sessions — the
`and`-expr commit alone added +50. The comments aren't *wrong*, they're **3–4× too long**: one
load-bearing *why* buried in 12–24 lines of restating-the-code + example-lists + the-same-idea-twice.
**How to apply:** a comment earns its lines only by what the code *can't* say — the non-obvious why,
the danger, the gotcha. Don't narrate what the next line plainly does, don't list examples the reader
can infer, don't re-explain. Compress a fat block to the 1–6 lines that carry the why; default to
fewer. Write lean from the start, not lavish-then-trim.

**No random mid-sentence capitalisation for emphasis.** (User, 2026-07-30: "I don't like the randomly
capitalised words," after I wrote comments like "a cell only DRAWS once it's in THIS commission's set"
and "throttled — heard_at is stamped ONLY by swarm frames … for its WHOLE duration … the SAME clock.")
**Why:** it reads as shouting, not emphasis; plain prose carries the weight fine. **How to apply:**
lowercase ordinary words even where I'd naturally lean on one while writing (only/whole/same/this/never
etc.) — use *italics-equivalent* phrasing or just trust word order instead. Reserve caps for what's
actually capitalized: proper nouns, %Mainkeys, acronyms, named constants (HTTP, LIB_TTL), section-style
title tags a docstring already uses (e.g. an existing "ALWAYS-ON:" heading in inherited code is fine to
match, not to imitate elsewhere). This applies to chat prose too, not just code comments.
