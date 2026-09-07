# Brief for the metaphysics agent — jamsend, 2026-09-07

You are being handed a codebase whose owner is trying to separate an *app* (music: what a track is and how its
bytes move) from a *social substrate* (who may act, how a frame crosses), and to make the whole thing
"un-screw-uppable for the next app." A two-day bug that lived entirely in the seam between those two layers
just got fixed; a twelve-reader sweep of the design corpus followed. Your job is to synthesise the purer
shapes out of what was found. Repo: `/app`. Docs: `src/lib/O/spec/` (working `*_todo.md`; blessed `*_spec.md`;
retired `history/` — each retired doc's top notice says where its living content went).

## Read in this order

1. `/app/CLAUDE.md` — the mechanics and the one bet: *turn every kind of state — a song, a test, a friendship,
   an error — into the same legible living matter, held where a group can see it, prove it, and rewrite it
   while it runs.* Note the C-object law: a thing exists ONCE under a container as its mainkey (the holding);
   anything naming it elsewhere is a referring particle wearing its own mainkey.
2. `spec/Homethink_todo.md` — the posture; the community of ghosts; "would the community SEE it, PROVE it, or
   REWRITE it while it runs? If you cannot say which, it is a particle."
3. `spec/Fallen_out_of_mind_todo.md` — the guide to the sweep. §0 the arc; §1 the table of things the owner
   already RULED that later work re-derived; §2–§8 by theme; §10 (the owner says: "wants blowing up and
   thinking about more"); §12 the `%see` census — what the system says about itself in 341 sentences.
4. `spec/ulative/fallen-out-of-mind-2026-09-07/finds_00..12.md` — the twelve raw reports, line-numbered.
5. `spec/Social_demarcation_todo.md` §3.3 (the two vocabularies as facing armies, the frontier between) and §8
   (nine flaws + the invite pivot, each with the owner's words).
6. `spec/SoundPooling_todo.md` §0 — the autopsy of the seam bug; `spec/Crew_todo.md` §2, §6, §9 — the settled
   social words, the ceremony, the durable laws.
7. Then by theme as needed: data — `Cstructures_todo`, `Statehome_todo` (the owner's "Phenomenology
   chapter" on `.c` vs `.sc`), `Seemables_todo`, `Mag_design`; wire — `Peeroleum_spec`, `Repli_design`
   (+ today's addendum), `Backpressure_todo`; attention — `Hovercraft.design`, `Datalayer_todo`,
   `history/Reqdrop_todo`; seeing — `Vyto_spec`, `Cello_synthesis_todo`, `InkSurprise_todo`; society —
   `Swarm_spec`, `Pier_todo`, `Presence_todo`, `Reach_todo`, `Trust_todo`, `history/Division_todo`.

## The purer shapes, as the corpus states them (lift these; test them against each other)

- **One holding, many referrers.** "There's only one of anything" (owner, 2026-07-14). A `%Card` beside a
  `%Record` on a shared id; a many:1 wears `of:`. Violation tell: *two shapes under one mainkey.* Applied
  four times, forgotten in between; the owner's precedent each time is to rename at once. The invariant now
  proposed: a `%Record` always has bytes or a `total` that promises them; identity-without-bytes is a
  `%Card`. Open: `Cello_synthesis §R.8` — the prior may need keying by *context* (the referrer), not mainkey.
- **A reference is its own word; the language never confuses being with pointing-at** (`Springcore_meander`).
- **Presence is fill state.** A chunk becomes real the moment its bytes land; no counters. Gaps are
  legitimate; "held" ≠ "covered"; a high-water mark must never answer a coverage question.
- **Data crosses and unlocks a level.** Grant, page, charter, catalog, invite are one move — "some type of
  data our peers want to give us, that unlocks further levels of communication." Owner's word for the QR:
  "come here" — a rendezvous, not a direction.
- **Absence is not deletion** (over the wire, a cleared key stays set on the mirror) — a contract owed since
  08-05; and **authoritative absence** (`history/Robustness_plan` Organ 3): a read is present | absent |
  unavailable; a transient read never overwrites durable data. Ruled app-wide, canonical nowhere.
- **The req pile IS the standard; the transport avoided the beliefs MUTEX, not reqs.** "A req is a proto-w —
  lighter and curlier, that does its work and finishes rather than persisting." Transient reqs are
  scaffolding, dropped when served; "leave in the snap only the reqs whose in-flight state is worth SEEING."
  Wake ≠ Hold. Capture (lexical) and work (maz) never merge. "The beat stops being the worker and stays the
  clock"; detached work returns via `reqyoncile`.
- **A desire is a C; a resolution is a C; the work between them is a local req, minted beside the foreign
  particle, never on it, and never replicated.** Two mirror shelves, one direction each. Today's proposal:
  a Seem hosts that lifecycle (`D//U/req`; neu/survivor/goner = mint/stand/stall-then-destroy) —
  `Fallen §3`, `Repli_design` addendum. Repli's own verdict on itself: "half-uses the machine's awareness
  primitive and hand-rolls the other half."
- **Attention became geometry** (`VytoWeb`); "the path to the focus is never folded"; "attention is a cycle
  not a consumption"; ink ∝ surprise — "honesty and compression are the same mechanism."
- **"Peering = who we listen as, Pier = who we dial"; for/from are identities, never addresses; resolve-and-
  emit, no liveness cache — reify EVENTS, never kept-fresh verdicts** (`Crew_todo §9`). Resolution (Post →
  body → address, off the Charter, pure) is split from reachability (learned by sending) — ruled in
  `history/Division_todo`, then lost.
- **The frontier**: an app should be drillable against a fixture peer with *no* social world at all. Every
  Book today stands on one side only (`Social_demarcation §7`).

## The open metaphysical questions the owner wants thought about

1. **The schema an app declares.** "Whatever I'm going for fits into a schema that particular apps can
   define, then it helps present|track the details of that language, which is a mixed language (mainkey, etc
   type meanings)." Story's machinery (beliefs trace, dige, `%see`, snap/diff) made generally available to
   the protocol it examines, reading one declaration. What is the declaration's shape? (`Story_hygiene §0`.)
2. **Card vs Record vs husk — now a concrete three-way ruling, and the owner wants YOUR read first.** The
   migration is sized at one mint, one un-mint, one reader, zero fixtures (`Fallen §2.1`). The catch: a
   heard-Mag `%Card` is `(id, pub)` under `Mag/Cloud`, a durable ledger row; a describe Card would be
   keep-id'd under a swept `RummageLib`. Same mainkey, different container/key/lifetime — the very sin being
   cured, moved one mainkey over. Options: (1) one `%Card`, context-keyed prior (makes `Cello_synthesis
   §R.8` load-bearing); (2) a distinct mainkey for the scratch catalog (the owner's rename-at-once
   precedent); (3) keep `%Record`, mandatory `total`. The session leans 2. Which is the same law, which is a
   new word, and does "a reference is its own word" settle it?
3. **Soul / Crew key / Body / Post** — the owner dislikes "soul"; a friendship as a Crew with a *set of doors*
   and a natural state machine per door (unknown → known → live → quiet → gone); whether a protocol resolves
   a post or the Crew does, once for all protocols (`Trust_todo`).
4. **The invite as rendezvous** and the pivot ("on the 'you got Invited' page we should be able to suddenly
   pivot to inviting them") — where mutual consent + SAS return.
5. **Seem-hosted lifecycle for foreign particles** — is `D//U` the general home for "my state about your
   matter"? What is the stall-then-destroy process, and who owns the destroy?
6. **The daemon**: "wants no SP" — a headless body has no taste; it serves from the library via the
   materialise scratch and declares serve-only. Is "a body with no taste" a general role?
7. **§10 of the guide** — now whittled from ~30 code-only rules to 12 standing laws with a doc home each,
   every instance judged at its cited line (20 LAW, 8 already-documented, 6 DONE, 1 UNCLEAR, 0 superseded,
   0 drifted). Two corrections worth knowing: "the heart IS the heist" is a *finished* design, not a slogan;
   and the album-grab Heist is NOT dormant (⏎ still seeds the album) — only the ♥ path changed, hence law #1
   "two gestures, two shapes." The question for you: which of the 12 are the SAME law in different clothes?
8. **Two live docs contradict** on whether presence rides `.c` or `.sc` (`Network_procedures` Phase 2 vs
   `Statehome §6`). And the general question underneath: what belongs in `.c` at all, once EntropyArrest
   forgives churn?
9. **The target image**: "some device floating around in the background of the Radio UI, which pieces float
   up from to get on the Radio… stretching a cell over some series of nodes… a lake of somethingness
   including a set of somethings." What is the *shape* of that, in particles, before it is a picture?

## What it is like

Written by sessions to sessions, dense, with the owner's voice quoted in as commissions and steers; uneven —
blessed specs, working todos, handovers that became load-bearing; decisions made, archived, re-derived. The
owner reads `%see` sentences as poetry as much as proof: "the frozen copy is a wire fact not a fiction";
"a heist begins soft — a wish sentence and no pier and no ids — barely more than meaning"; "silence is the
honest answer for what a peer lacks." Aim your synthesis at that register: short, exact, in the corpus's own
words where they exist, and honest about which shapes are law, which are ruled-but-unbuilt, and which are
still wishes.
