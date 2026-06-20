# Observations on the project and the work

A few observations, grounded in what I actually touched this session rather than
the README version of things.

## On the architecture

The thing that stands out is that the *real* system isn't the music app — it's
the authored machine on top: the C/particle model, ghosts, and the snap
serialization. The streaming is almost incidental. And that machine is unusually
**homoiconic** — everything is a `C`, the snap is just the text projection of the
live tree, and the Story runner's whole notion of "did it work" is *diffing two
snapshots of that tree*. That's a genuinely powerful invariant-checking design:
state, tests, and persistence are the same substrate.

The `.sc`/`.c` split (scalars persisted, objects/refs runtime-only, object-in-`sc`
fatal at encode) is the load-bearing discipline that makes it work, and it's
enforced at the right place — encode time, fatally. Clean.

## What the bug revealed

The graft bug is a small instance of a structural tension worth naming:

1. **`encode_stringies`' JSON fallback is a double-edged safety net.** It exists
   so no data is ever lost — but that means an `undefined` value (a *real* bug)
   doesn't fail loudly; it silently degrades a clean peel line into a JSON blob
   and *drops the offending keys*. The corruption only surfaced because a human
   was eyeballing a snap diff. The fallback protects data integrity at the cost of
   hiding correctness bugs. That's the right trade for persistence, but it means
   the snap diff is doing double duty as your only bug detector for this class.

2. **The snap diff can't see the silent half.** The graft (a serialized value)
   showed up as JSON; the `e_Lang_goto_point` straggler (a navigation jump) was
   *invisible* to the diff because it never serializes — it just jumps to offset 0.
   Same root cause, but one was loud and one was silent. Anything your migrations
   break in *behavior* rather than *state* won't appear in a snap diff at all.

3. **The type checker can't help you migrate.** This is the real systemic risk.
   The rel-offset migration missed two readers, and there's no way the compiler
   could have caught `def.sc.from` going `undefined` — `sc` is an untyped bag, and
   the ~3k "Property X does not exist on House" warnings mean you've already opted
   out of leaning on types. So a rename like `from`→`rel_from` has a blast radius
   that's only discoverable by grep + reasoning, exactly what we just did by hand.
   `Lang_map_span` is the correct centralization (every reader *should* funnel
   through it), but nothing *enforces* that — adoption is by convention, which is
   why two readers slipped.

## On the workflow

- **Host-commits-mid-session is a real, recurring hazard** — it bit us (HEAD moved
  under me, absorbing the fixes). The fact that it's already a memory note tells me
  this isn't the first time. The mitigation is cheap (re-check `git status` after
  any surprise), but the workflow structurally invites it: a human on the host and
  an agent in the container editing the same tree.
- **The relative-offset migration is the right instinct.** Encoding offsets
  region-relative so an edit above doesn't churn every line below is a real,
  thoughtful reduction of snap noise — and snap noise directly costs you, because
  the diff is your test signal. The follow-up (de-snapping the Navicade/Mapule
  cache since it's rebuilt every compile) is the cleaner end-state and fits the
  project's stated "remove machinery" doctrine.

## One suggestion

If migrations of `sc` keys keep recurring (and the memory trail suggests they do —
Doc/Dock rename, oai/moai, this one), the single highest-leverage guardrail would
be making the JSON-blob fallback **noisy in dev**: when `encode_stringies` falls
back *because of an `undefined`/non-scalar value* (as opposed to a legitimately
colon-laden string), `log()` or `console.warn` it. That converts the entire
silent-corruption class into a visible signal at the moment it happens, instead of
waiting for a human to spot a blob in a diff. It's a few lines in `Text.svelte` and
it would have caught the graft bug on the first compile, before the snap.

Overall: the work was a clean, well-scoped bug hunt — but the more interesting
takeaway is that this codebase's safety rests almost entirely on *snap-diff
vigilance*, and that net has two holes (silent behavioral bugs, and the JSON
fallback masking bad values). Both are patchable.
