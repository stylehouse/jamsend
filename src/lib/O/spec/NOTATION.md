# Notation — the House lingo

The conventions for writing about TheC objects and for code comments in this codebase.
Honour them in comments and in code. When the Navicade|Mapule module lands this can
become its header comment instead of a standalone file.

## C objects (TheC particles)

- A particle is named by its **mainkey**. Refer to it by the mainkey, not a local
  alias: write `%Point`, not `let Text_C = …` then `Text_C`.
- `%Text` — the particle whose mainkey is `Text`, alone.
- `Text%dige` — the `dige` of `%Text` (a property/derived reached off it).
- `%like,this` — a structure written alone (mainkey `like` carrying `this`).
- `and/like,this/written:is` — structures written inside other structures (the `/`
  steps into a host).
- `%LE` means `{LE:1}` — a value-1 flag serialises as the bare key. So `def` = `def:1`,
  `line` = `line:1`. Don't write `%LE,1`.
- Exception: when it's obvious the property carries an unwritten value, the bare form
  still implies it — e.g. `%Spotlight,src` means Spotlight with some `src` value, not
  `src:1`.
- Written with an **explicit value**, drop the `%`: `CreduCoherence:latest`,
  `run_result:100%`, `req:Languish`. The `%` is the **lone-key** form (`%Credulate`,
  `%Book`, `%GhostInclude` as a type/ledger).
- `%Point:name` — the spec rides as the Point value (`{Point:name}`), preferred over
  `%Point,method:name`. Resolution crawls `%Map` by name, never by stored absolute
  offset.

## Tuples floating in language

- `%kind,key,path,depth` — how to write a **tuple floating in language**: an anonymous
  structure carrying those keys. (This is the shape of one Mapule.)

## Methods, events, components

- `name()` — a **method/function**, written with parens: `Cred_ghost_versions()`,
  `beliefs()`, `i_elvisto()`. Tells a call apart from a particle key.
- `e:name` — an **elvis event** (the dispatch); its handler is the method
  `e_<Target>_<name>()` — `e:dock_content` → `e_Lang_dock_content()`.
- `UI:Name` — a **Svelte component / mounted face**: `UI:CreduFunk`, `UI:Liesui`.

## Compound type names — `|` and `/`

In a compound proper-noun **type name**:
- `|` means **and** — `Navicade|Mapule` is the Navicade-and-Mapule pair (two concepts
  named together).
- `/` means **host-of** — `Navicade/Mapule` is Navicade hosting Mapulen, `dock/%Map` is
  the dock hosting its Map.

## Code-comment prose — `|` and `/`

In ordinary comment prose (distinct from type names above):
- `|` means **this or that** — `decl|call`, `if inside/this|that`. Don't write `this/that`
  for alternation; `/` is inside-ness, not "or".
- `/` means **inside-ness** — `if inside/this|that` reads "if inside this-or-that".

## Comments

- Comments are **eternal**. Keep the ones still true when rewriting code; drop nothing
  that still helps a human. No dev-mumbling — never `<- NEW`, never `// no blah needed`
  right after blah was removed.
- `// <` marks a **lack of development** — a deferred gap, a thing not yet built.
- Nest a stack of not-too-long sentences, the way a thought trails off into a subject
  like that
    as things often do
  or moving on.
- **Indent is the branch** — a deeper line is subordinate to, or a consequence of, the
  one above. Don't mark it (no `↳`); the indent already says so.
- `→` is **inline flow** — "leads to", left-to-right on one line: `compile → settle → run`.
- Don't randomly cap lengths for presentation; a reliable measurement is reported whole
  unless a limit is actually wanted.
