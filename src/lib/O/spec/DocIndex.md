# DocIndex — the topics, and the one doc to open for each

**What this is.** The front door to `spec/`. jamsend's design is spread over ~120 docs; this names the **topics** it's
 really about, in four sections, and for each topic the **front-door doc**: the one to open first, which says what the
  field IS and points onward. Everything else in `spec/` hangs under a topic as a companion.
 *(The off-tab doc index the dev server writes — once `Docindex_todo.md` — now lives in `Wordland_todo.md` §3.)*

**How the docs are meant to work** (owner, 2026-10-15): a front door is a **permanent, uncreased description of the
 field's wider scope**: what it is, why, what's settled and what's still open. It isn't a log of the last wave of work.
  Wave-of-work docs (handovers, evening-by-evening hunts) are scraped into their topic's front door and retired to
   `history/`. CLAUDE.md has the naming rules (`_todo` is the default; `_spec` is earned; `history/` keeps the rest).

**Keep this current.** When a doc is born, retired or renamed, fix its row here.

**The four sections** (owner, 2026-10-16):
- **I. Metaphysics and the code itself**: the explosive expansion, standing on Stuff and Housing. *"we are building a
   language back there once I get around to it."*
- **II. The app foundation**: what any app on this engine gets (cluster, wire, trust, crew, a person's model).
- **III. Jamsend**: this particular app, music between friends.
- **IV. The visual end**: how all of it is drawn (the glass, and Cello, which the app foundation owns rather than Jamsend).

The bet runs under all four: **`Homethink_todo.md`**, the posture (every kind of state as legible living matter a group
 can see, prove and rewrite; the tells that it's being broken), with `Emotion_todo.md` (the will that drives the land).

## I. Metaphysics and the code itself — the explosive expansion

| # | topic | front door | what the field is | companions |
|---|---|---|---|---|
| 1 | **The foundation: Stuff and Housing** | `Datalayer_todo.md` | `C` particles, `Stuff`, `Housing`, the req machine (Hovercraft): what everything else stands on. Be very careful changing it | `Stuff_todo.md` (the k:v regrouping algebra), `Hovercraft.design.md`, `Statehome_todo.md` (where a datum lives: `.sc` vs `.c`), `Statemap_todo.md`, `reactivity_docs.md` (hopefully a naive Atheory: what Stuffing-style reactivity becomes once generalised) |
| 2 | **Atheory: the rebuild** | `Atheory_todo.md` | A**, the next rebuild of Housing: load lists, the A** shape, the merge organ (Se → Merge), the spheres, and the case studies that feed it | `Atheory_design.md` (what is built, and the ledger of every change to Stuff/Housing), `Focus_todo.md` (its twin, the focus authority), `Seemables_todo.md` (`%Seem`), `Whitehole_todo.md` (the new platform: the Seem wall), `Spec_tidy_todo.md` (this era's doc tidy) |
| 2b | **Aprac: building on Atheory** | `Aprac_todo.md` | the practice on top of the theory: views (`Ghost/A/Stuffica.g` — Stuffing made a citizen), `/Pondland`, the UI pattern, a contained game, then Hackarium rebuilt within our walls | `Atheory_design.md` §1.13 (the scheduler, IO, holds), `Wire_spec.md`, `reactivity_docs.md` |
| 3 | **The language** | `Cstructures_todo.md` | the readable C** language being built "back there": how a structure is said, and what the Se wants of every saying (provenance, rule, pass) | `stho_primer.md`, `NOTATION.md`, `Springcore_meander.md` (the world's springy linguistic core), `LangSolver_report.md` (what an IOing expression becomes), `IOexpr_todo.md` (IOexpr sites as synapse ends: Map rows, the derived shape census, conduits, `%TheASpilled`), `LangCompiler_TODO.md` |
| 4 | **Performance** | `Perf_todo.md` | what the machine costs to run and why: passes, wakes, the idle floor; the measured cases Atheory must answer | `Backpressure_todo.md`, `Cellsizing_todo.md` |
| 5 | **Story and Books** | `Story_hygiene_todo.md` | the test/story runner: Books, snaps, sworn assertions, fixtures, running them on a live runner | `Seen_split_todo.md` (`%see` → sworn), `EntropyArrest.md`, `Composition_todo.md`, `Story_future.md` + `Story_future_directions.md`, `Story_cli_docs.md`, `Sounditron_todo.md` (the resident diagnostic Book), `Radiation_determinism_todo.md` |
| 6 | **Editron: the current editor and the compiler** | `Editron.md` | the `role:editor` webapp — the one writer: the compile/run pipeline for editable docks, editor ↔ runner, Credence, the Lang/Lies attention channel.  Its organs are moving into Wordland (#7) | **`LiesLang_todo.md` (the map of the whole Lies\|Lang machine — start there)**, `Lies_attention_todo.md`, `Interest.md`, `LiesEnd_spec.md`, `GhostHMR_todo.md`, `Keeping_spec.md`, `Lens_posable_TODO.md`, `Error_channel_todo.md`, `CodeReview_todo.md` |
| 7 | **Wordland: the land and the editor being built** | `Wordland_todo.md` | the code made legible — Atlas (what it says), Electrode (what it does), the index the watcher writes — and the room that reads it: BigWordland, `role:hacker`, search-first (the cave), the modern editor growing out of Editron's organs | `Lagoon_todo.md` (the reader layer), `Glassbeast_todo.md` "THE CAVE" log entries (the cave's live log), `Stemdex_todo.md` + `Stemdex_spec.md`, `Electrode_todo.md`, `Verbs_todo.md` (a terminal's controls, the Workshop), `Clerkdesk_todo.md`, `Interest.md` (focus), `Waft_styling_todo.md` |

Reference for this section (read, don't plan from): `Coding_guide.md` (read before touching the belief loop: wake ≠ hold,
 ttlilt, the compile→rerun chain), `NOTATION.md`, `stho_primer.md`, `reactivity_docs.md`, `Hovercraft.design.md`.

## II. The app foundation

What any app built on the engine gets: a person with bodies and friends, a wire between them, proof of who's who. The line
 between this and Jamsend is itself a design question: **`Social_demarcation_todo.md`** (the substrate/app boundary, and the
  accessor it never had).

| # | topic | front door | what the field is | companions |
|---|---|---|---|---|
| 8 | **The app, as a person meets it** | `App_todo.md` | a person, their bodies, their friends and what passes between them, walked in life order: arriving (§0.7), the Door, crew, hearing, acquiring, persisting | `Arrival_todo.md` (the arrival state machine), `Persistence_todo.md`, `Portability_todo.md` + `Portability_doc.md` (phones, listen-only), `Presence_todo.md`, `UI_seams_todo.md` |
| 9 | **Crew and identity** | `Crew_todo.md` | souls and bodies: one identity on many devices (Captain, Caves), `Grant:Crew`, the charter, linking a device, invites | `LinkDevice_leak_todo.md`, `Identity_persist_todo.md`, `Swarm_spec.md` (the p2p social side), `Swarm_compact_invite_todo.md`, `Pier_todo.md`, `Grantwalk_handover.md` |
| 10 | **Trust** | `Trust_todo.md` §0–§1 | what's cryptographically real on the wire and what isn't; the session-key plan (WT1–4); trust ceremonies as one substrate (§3–§4) | `Signed_call_todo.md` (signed RPC over the relay), `Sharing_design.md`, `Crew_todo.md` |
| 11 | **The wire** | `Peeroleum_spec.md` | how a frame crosses: carriers, the relay, outbox/inbox, the handshake, Repli (catalog + pages), Reach (cross-body work) | `Wire_spec.md`, `Repli_design.md`, `Repli_idspace_todo.md`, `Reach_todo.md`, `Backpressure_todo.md`, `Netsitu_todo.md`, `Network_procedures_todo.md` (how to build a multi-party feature), `Networky_directions_todo.md`, `Peeroleum_handover.md` |
| 12 | **Cluster, relay and runners** | `Cluster_spec.md` | the relay, addressing, how a tab boots into a role, how runners are found and courted | `ClusterAddressing_todo.md`, `Engage_integration.md` |

Cello (#21) is owned by this section too: it's the app foundation's cells and Door, filed under IV because it's drawn.

## III. Jamsend — this app: music between friends

| # | topic | front door | what the field is | companions |
|---|---|---|---|---|
| 13 | **Radio** | `Radio_todo.md` §0 | listening together: the Stoker conveyor, the dial, the ♥, all on `Ghost/M/*.g` | `Radio_spec.md` (stage map), `Radio_design.md`, `Radio_todo.md` §0.d (every `Ghost/M` ghost in one sentence, and what was cut), `Radio_circuit_todo.md` + `Love_todo.md` (the ♥ and the heard Mag), `Supervisor_todo.md` (knowing when to give up and reload), `Radio_lowlevel.md` + `Radiobuddies_handover.md` (kept archaeology) |
| 14 | **The magazine** | `Mag_todo.md` §0 | what's been heard and liked: `%Mag:heard` of `%Card`s, one Card two roads, the referring-particle rule. Foundation-ended (a Mag is a Waft of Clouds), but it lives in this app | `Radio_circuit_todo.md` |
| 15 | **Acquiring music** | `Heist_todo.md` §0 | ♥ → the whole album on disk: the pump, the window, landing, the Haul | `RemoteHeist_todo.md` (heisting on another body, `Heist_defaults`), `Heist_design.md` |
| 16 | **The pool** | `SoundPooling_todo.md` | what played is kept and re-circulated; the pool holders; lofi copies for folderless bodies | |
| 17 | **The collection** | `Wander_todo.md` | a library too big to enumerate: fair shuffling, the foggy map of what's there, whole tracks carried in your pocket | `Census_todo.md` |
| 18 | **Ways of listening** | `Radio_future.md` | the imagination ledger of listening, and the shapes it takes: alone, following a DJ, many at once, the phone as instrument | `Solo_todo.md` (the lonely Radio), `Radio_multicast_todo.md` (following a DJ and the phone as instrument are one line each in `Radio_future.md` §13) |
| 19 | **The daemon** | `Daemon_todo.md` | jamserve: the headless resident body that serves the music; its weight, its loop, its HTTP introspection. (A resident body is a foundation idea; this one is Jamsend's) | `Perf_todo.md` §7 |

## IV. The visual end

| # | topic | front door | what the field is | companions |
|---|---|---|---|---|
| 20 | **The glass** | `Glassbeast_todo.md` §0 | how state is drawn: Vyto (the renderer), Voro (the stained glass), Cyto | `Meaningfold_todo.md` (rulings), `Glassbeast_voice.md` (the owner's words), `Vyto_spec.md`, `Vyto_sizing_todo.md`, `Vyto_client.md`, `Voromay_todo.md`, `Attractor_todo.md`, `Glass_reduction_todo.md`, `Snappy_todo.md` |
| 21 | **Cello: cells and the Door** | `Cello_todo.md` | the app's cells: Cellui's fit, the glass kinds (Door, Radio, Heist, Haul, Pier…), commissions. Owned by the app foundation (II), not Jamsend; Jamsend fills it with music cells | `Cello_synthesis_todo.md` + `Cello_meditation_todo.md` (the residual lens), `InkSurprise_todo.md`, `WikipediaCell_todo.md` |

## Ledgers and sweeps (cross-topic)

`Fallen_out_of_mind_todo.md` (social/attention designs already ruled: read before redesigning), `Loose_ends_todo.md`,
 `Everything_todo.md` (the cross-spec index of 2026-09), `Frontier.md`, `V1_cut_todo.md`.

## Where the code's own front door is

`wormhole/Ghost/Everything/toc.snap`: one `What` per area of the program, each listing that area's main methods. Generated by
 `scripts/wafts_everything.mjs` (CLAUDE.md, "Read Waft:Everything first").
