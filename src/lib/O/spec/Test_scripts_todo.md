# Test scripts — every test that is NOT a Book

## 0. What this is, and the rule going forward

Books live in `wormhole/Credence/toc.snap`, one row each, run on a live runner.  Everything else that tests something — a vitest
 spec, a node proof, a headless browser eye — was described only in its own header comment, so nobody could list them
  (2026-11-15, the owner: "definitely enumerate and describe each other test script we make going forward so they're somewhere").
   **This file is that list.**

- **A new test script gets a row here in the same change**, under the right heading: name, one line on what it proves, how to run
   it if not the usual form.  Retiring one deletes its row.
- **The commit gate is `npm run checks`** (`scripts/checks.mjs`): the vitest specs marked ✅ below + `relay-test.ts`.  A spec
   earns ✅ by guarding something a commit can quietly break; add it to `checks.mjs`'s `VITEST` list and mark it here.
- **The usual vitest form:** `node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/<Name>.spec.ts` (a headless
   stub House in jsdom — no runner, no browser).  Node proofs: `npx tsx scripts/<name>-test.ts` (or `vite-node`).
- **Owed — runner infra for these (unbuilt idea).**  A runner could one day run a script test the way it runs a Book, with a
   Credence-like row and a verdict on the wire.  Not designed; a `Funkcion:Scripting` row in Credence was floated and dropped
    (the owner: "I have no idea where Funkcion:Scripting is going").  Until then: this list.
- ⚠ **A headless green is not a live green.** `Story_cli*` boots the machine under jsdom with real disk — a bubble (CLAUDE.md).
   The eyes below run a REAL browser against the REAL dev server and are closer to the truth, but are still a fresh profile.

## 1. Node proofs — the relay and the trust contracts (no browser)

| script | proves |
|---|---|
| ✅ `relay-test.ts` | the `/relay`: same-origin + cross-relay delivery, signed hello binds, forged hello refused, individuation, `who`, the r2r bridge, twin tabs of a Cave (seat before courtesy bind, the heir rule, `family_gone` on close).  `RELAY_MOD=<copy.ts>` tests a scratch relay without saving `relay.ts` (a save restarts the dev server).  ⚠ "cross-relay deliver resumes after reconnect" flakes on the old relay too |
| `runner-ask-test.ts` | runner_ask / runner_ack corr-routing through one relay with a fake runner (4 checks failing, known, unfixed) |
| `ceremony-addr-test.ts` | the `${prepub}_${rid}` addressing model — the multi-body device-link scenario on one in-process relay |
| `cluster-trust-test.ts` | `cluster_trust.ts` sign→verify contract behind the relay's gen_write gate and the flock |
| `crew-cert-test.ts` | the cert-crew trust token — `Grant:Crew` from the Captain trusted by others |

## 2. Headless browser eyes — a real Chromium against the real dev server

Need `~/chromelibs` (see the eye memory).  Each mints its own identity in its own profile and touches nobody's tab.  **Run one at a
 time** — six Chromiums at once crashed Chrome (2026-11-15).

| script | proves / shows |
|---|---|
| `twin_eye.mjs` | tabs of ONE profile through a plan: `--plan="open:A wait:30 open:B wait:30 crash:A wait:30"` — steps `open`/`reload`/`close`/`crash`/`wait:N`/`slow:X` (delays the IndexedDB probe); verdict = one bare holder, siblings `_N`, nobody memory-only; exit 1 on bad.  Use `/BigSoundland` (a fresh `/Radio` mints no identity).  Spec: `Identity_persist_todo.md` §0.1 |
| `arrival_eye.mjs` | be a newcomer: open a page, click/type on a schedule, photograph it, keep body text + console + every relay frame |
| `runner_eye.mjs` | photograph a live page over time (`node scripts/runner_eye.mjs <url> <outprefix> [secs,…]`) |

## 3. Compile and import gates

| script | proves |
|---|---|
| `LocalGen.spec.ts` | the browserless `.g → .go` compiler (`GFILES="Ghost/X/Y.g"` to pick files).  ⚠ misses a `let` redeclaration — esbuild-parse the `.go` after |
| `GhostCompile.spec.ts` | a `.g` dialect parses and lowers (the generalised pre-compile gate) |
| `FlockCompile.spec.ts` | the fixed flock of `%Pier,…,req` edits through the real in-app translator — pinned on purpose |
| ✅ `RehealSmoke.spec.ts` | the written `gen/M/Ra.go` + `gen/N/Repli.go` compile, mount, and deposit their methods on H |
| `LakeRace.spec.ts` | the CLI's ghost_compile against the real `Peeroleum.g`, headless — the one-round lag is dead |
| `FlavourElectrode.spec.ts` | the measuring build (`flavour_electrode.ts`) is text-for-text with the plain one |
| `CredulerProbe.spec.ts` | a runner can ACQUIRE its spine (Creduler gen `.go`) and deposit onto H, headless |

## 4. Unit specs — ghost logic on a stub House

**Swarm / crew / identity**
| script | proves |
|---|---|
| `TwoFounder.spec.ts` | two identities of one account converge on Captain + sibling (the two-founder gate) |
| `MembershipDoor.spec.ts` | `Swarm_pier_retired` / `Swarm_peers` — which peers the membership door admits |
| `HackerRole.spec.ts` | `role:hacker` — the one-editor rule and the hacker room's refusals |
| `Presence.spec.ts` | the batch presence probe: a real relay answering a real `who`, absorbed by `Presence_*` (own config `Presence.vitest.config.mjs`) |
| `SendTo.spec.ts` | `Peeroleum_send_to` picks the Pier by `%pub`, so an editor can address ONE runner |

**Heist / pool / supply**
| script | proves |
|---|---|
| ✅ `HeistUnity.spec.ts` | the unity, the blag's handover, the heist queue |
| ✅ `MultiHeist.spec.ts` | the multiple-heists cut and the what-heisted ledger |
| ✅ `HeistCostLine.spec.ts` | the owner's "only showing 1 track" bug, pinned |
| ✅ `KeepMemoDurable.spec.ts` | the durable keep-memo and the re-materialise contract |
| ✅ `Newlyadded.spec.ts` | the download ledger's Mag join, and the rename that must not eat rows |
| ✅ `ParkCull.spec.ts` | the want-lease: a `%parked_want` nobody re-asks is culled |
| `PoolKeep.spec.ts` | the pool's candidate draw and its one-track keep |
| `ServeResolve.spec.ts` | id → `%Record` resolution that serves bytes |
| `ReachTerminal.spec.ts` | a `%Reach`'s terminal states |
| `SupplyGuards.spec.ts` | the supply-side predicates |

**Faces (Svelte in jsdom)**
| script | proves |
|---|---|
| ✅ `HaulFace.spec.ts` | the Haul cell actually draws (the only way in) |
| ✅ `ButlerPatience.spec.ts` | the two sentences the Butler says while still working |
| ✅ `BootGateNoFSA.spec.ts` | a browser with no folder picker gets a sentence, not a dead button |

**Nav / docs / land**
| script | proves |
|---|---|
| `MountNav.spec.ts` | the mount table over a duck-typed nav |
| `LazyGithubNav.spec.ts` | the lazy GitHub app tree downloads only what a step diffs |
| `StatusWaft.spec.ts` | the dev server writes a Waft the tab's own decoder reads (Docindex first slice) |
| `IndexRoster.spec.ts` | Atlas rosters from the index Waft instead of walking the tree |
| `MapEncode.spec.ts` | the Map/index serialises as C** |
| `StemdexDefs.spec.ts` | the Stemdex can see a ghost method |
| `LinkKinds.spec.ts` | the markdown doc-link collector in `compile.ts` |
| `SectResolve.spec.ts` | how a `§` link resolves (the reader half) |
| `OathJoin.spec.ts` | the oath constellation: `story_swear` sites collected + joined |

**Vyto geometry** — `VytoFocus` (nobody is swallowed, pure function), `VytoFoldLadder` (where a wall falls), `VytoGauge` (a box can
 fall), `VytoPane` (the folio's geometry), `VytoPile` (the hand's law), `VytoSeat` (the seat partition).

## 5. Measurements, not gates — "why is opening a doc slow"

`DocLoad.spec.ts` (the compiler called directly), `DocOpen.spec.ts` (the other half — the real open path), `CM6Mount.spec.ts`
 (CodeMirror's own cost), `GrammarBuild.spec.ts` (is the lezer grammar rebuilt per mount).  Read numbers, don't expect a pass.

## 6. Runners of other tests (tools, listed so they are findable)

`runner_sweep.mjs` (many Books on a live runner, one line each — the real Book gate), `runner_shot.mjs` (the live Cyto canvas as
 PNG/SVG), `checks.mjs` (the commit gate above), `Story_cli.spec.ts` + `Story_cli_boot.spec.ts` + `Story_cli_sweep.mjs` +
  `CredRunner.spec.ts` (the headless Story runner — ⚠ a bubble, never a gate).
