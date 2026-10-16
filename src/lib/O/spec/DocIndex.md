# DocIndex — the topics, and the one doc to open for each

**What this is.** The front door to `spec/`. jamsend's design is spread over ~140 docs; this names the **~20 topics**
 it's really about, and for each one the **front-door doc**: the one to open first, which says what the field IS and
  points onward. Everything else in `spec/` hangs under one of these as a companion.
 *(Not `Docindex_todo.md`: that one is the code feature, the off-tab doc index the dev server writes.)*

**How the docs are meant to work** (owner, 2026-10-15): a front door is a **permanent, uncreased description of the
 field's wider scope**: what it is, why, what's settled and what's still open. It isn't a log of the last wave of work.
  Wave-of-work docs (handovers, evening-by-evening hunts) are scraped into their topic's front door and retired to
   `history/`. CLAUDE.md has the naming rules (`_todo` is the default; `_spec` is earned; `history/` keeps the rest).

**Keep this current.** When a doc is born, retired or renamed, fix its row here.

## The topics

| # | topic | front door | what the field is | companions |
|---|---|---|---|---|
| 1 | **The bet** | `Homethink_todo.md` | the posture: every kind of state as legible living matter a group can see, prove and rewrite; the tells that it's being broken | `Statehome_todo.md` (where a datum lives: `.sc` vs `.c`), `Statemap_todo.md`, `Emotion_todo.md` (the will) |
| 2 | **The next rebuild** | `Atheory_todo.md` | A**: the rebuild of Housing. Load lists, the A** shape, the merge organ (Se → Merge), and the case studies that feed it | `Focus_todo.md` (its twin, the focus authority), `Cstructures_todo.md` (the readable C** language), `Seemables_todo.md`, `Whitehole_todo.md` (the Seem wall), `Spec_tidy_todo.md` (this era's doc tidy) |
| 3 | **The app, as a person meets it** | `App_todo.md` | a person, their bodies, their friends and the music between them, walked in life order: arriving, the Door, crew, hearing, acquiring, persisting | `Arrival_todo.md` (the arrival state machine), `Persistence_todo.md`, `Portability_todo.md` + `Portability_doc.md` (phones, listen-only), `Solo_todo.md`, `Presence_todo.md`, `UI_seams_todo.md` |
| 4 | **Crew and identity** | `Crew_todo.md` | souls and bodies: one identity on many devices (Captain, Caves), `Grant:Crew`, the charter, linking a device, invites | `LinkDevice_leak_todo.md`, `Identity_persist_todo.md`, `Swarm_spec.md` (the p2p social side), `Swarm_compact_invite_todo.md`, `Pier_todo.md`, `Grantwalk_handover.md`, `Social_demarcation_todo.md` |
| 5 | **Radio** | `Radio_todo.md` §0 | listening together: the Stoker conveyor, the dial, the ♥, the resident serving body, all on `Ghost/M/*.g` | `Radio_spec.md` (stage map), `Radio_design.md`, `Radio_circuit_todo.md` + `Love_todo.md` (the ♥ and the heard Mag), `Radio_future.md` (imagination ledger), `Radio_multicast_todo.md`, `Wander_todo.md`, `Follow_todo.md`, `Census_todo.md`, `Supervisor_todo.md`, `Radio_lowlevel.md` + `Radiobuddies_handover.md` (kept archaeology) |
| 6 | **The magazine** | `Mag_todo.md` §0 | what's been heard and liked: `%Mag:heard` of `%Card`s, one Card two roads, the referring-particle rule | `Radio_circuit_todo.md` |
| 7 | **Acquiring music** | `Heist_todo.md` | ♥ → whole album on disk: the pump, the window, landing, the face | `RemoteHeist_todo.md` (heisting on another body, `Heist_defaults`), `Heist_design.md`, `Siphon_todo.md` |
| 8 | **The pool** | `SoundPooling_todo.md` | what played is kept and re-circulated; the pool holders; lofi copies for folderless bodies | |
| 9 | **The wire** | `Peeroleum_spec.md` | how a frame crosses: carriers, the relay, outbox/inbox, the handshake, Repli (catalog + audio pages), Reach (cross-body work) | `Wire_spec.md`, `Repli_design.md`, `Repli_idspace_todo.md`, `Reach_todo.md`, `Backpressure_todo.md`, `Netsitu_todo.md`, `Network_procedures_todo.md`, `Networky_directions_todo.md`, `Peeroleum_handover.md` |
| 10 | **Trust** | `Trust_todo.md` §0–§1 | what's cryptographically real on the wire and what isn't; the session-key plan (WT1–4); trust ceremonies as one substrate (§3–§4) | `Signed_call_todo.md` (signed RPC over the relay), `Sharing_design.md`, `Crew_todo.md` |
| 11 | **Cluster, relay and runners** | `Cluster_spec.md` | the relay, addressing, how a tab boots into a role, how runners are found and courted | `ClusterAddressing_todo.md`, `Engage_integration.md` |
| 12 | **The daemon** | `Daemon_todo.md` | jamserve: the headless resident body that serves music; its weight, its loop, its HTTP introspection | `Perf_todo.md` §7 |
| 13 | **Performance** | `Perf_todo.md` | what the machine costs to run and why: passes, wakes, the idle floor | `Backpressure_todo.md`, `Cellsizing_todo.md` |
| 14 | **Story and Books** | `Story_hygiene_todo.md` | the test/story runner: Books, snaps, sworn assertions, fixtures, running them on a live runner | `Seen_split_todo.md` (`%see` → sworn), `EntropyArrest.md`, `Composition_todo.md`, `Story_future.md` + `Story_future_directions.md`, `Story_cli_docs.md`, `Sounditron_todo.md` (the resident diagnostic Book), `Radiation_determinism_todo.md`, `Clerkdesk_todo.md` |
| 15 | **Lies: the editor and compiler** | `Editron.md` | the compile/run pipeline for editable docks, editor ↔ runner, the Lang/Lies attention channel | `Lies_attention_todo.md`, `Interest.md`, `LangCompiler_TODO.md`, `LangSolver_report.md`, `LiesEnd_spec.md`, `GhostHMR_todo.md`, `Keeping_spec.md`, `Lens_posable_TODO.md`, `Error_channel_todo.md`, `CodeReview_todo.md` |
| 16 | **The land (code as matter)** | `Wordland_todo.md` | the code itself made legible: Atlas (what it says), Electrode (what it does), BigWordland (the room) | `Lagoon_todo.md`, `Stemdex_todo.md` + `Stemdex_spec.md`, `Electrode_todo.md`, `Verbs_todo.md` (a tab's controls), `Docindex_todo.md`, `Waft_styling_todo.md`, `Springcore_meander.md` |
| 17 | **The glass** | `Glassbeast_todo.md` §0 | how state is drawn: Vyto (the renderer), Voro (the stained glass), Cyto | `Meaningfold_todo.md` (rulings), `Glassbeast_voice.md` (the owner's words), `Vyto_spec.md`, `Vyto_sizing_todo.md`, `Vyto_client.md`, `Voromay_todo.md`, `Attractor_todo.md`, `Glass_reduction_todo.md`, `Snappy_todo.md` |
| 18 | **Cello: cells and the Door** | `Cello_todo.md` | the music page's cells: Cellui's fit, the glass kinds (Door, Radio, Heist, Haul, Pier…), commissions | `Cello_synthesis_todo.md` + `Cello_meditation_todo.md` (the residual lens), `InkSurprise_todo.md`, `WikipediaCell_todo.md`, `Phone_instrument_todo.md` |
| 19 | **Data layer: Stuff and Housing** | `Datalayer_todo.md` | `C` particles, `Stuff`, `Housing`, the req machine (Hovercraft) | `Stuff_todo.md`, `Hovercraft.design.md`, `reactivity_docs.md` |

## Reference (read, don't plan from)

`Coding_guide.md` (read before touching the belief loop: wake ≠ hold, ttlilt, the compile→rerun chain),
 `NOTATION.md`, `stho_primer.md`, `reactivity_docs.md`, `Hovercraft.design.md`.

## Ledgers and sweeps (cross-topic)

`Fallen_out_of_mind_todo.md` (social/attention designs already ruled: read before redesigning), `Loose_ends_todo.md`,
 `Everything_todo.md` (the cross-spec index of 2026-09), `Frontier.md`, `V1_cut_todo.md`.

## Where the code's own front door is

`wormhole/Everything/toc.snap`: one `What` per area of the program, each listing that area's main methods. Generated by
 `scripts/wafts_everything.mjs` (CLAUDE.md, "Read Waft:Everything first").
