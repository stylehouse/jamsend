---
name: radiobuddies-shebang-unnamed
description: "'Radiobuddies' (owner's coinage) = run-a-music-node + share-with-your-friends + by-identity — currently UN-NAMED; the codebase factors it into the triad Cluster(how it runs)/Radio(what streams)/Swarm(who's on it). The ${pub}_N multi-instance identity has building blocks in Swarm.g (Swarm_take_role role∈{music|encode|serve}, to:<prepub>_N) but built for multi-tab robustness + name-theft defense, NOT friend-facing instance-discovery (absent; _N=same-key-vs-ephemeral is an OPEN spec question)"
metadata:
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

Owner asked "do we have a name for that whole shebang?" (running a music node that shares with your
 friends over p2p, by identity) and is coining **"Radiobuddies"**. Answer from a repo sweep:

**No single name exists — it's UN-NAMED.** The codebase deliberately factors it into a TRIAD, stated
 verbatim (`spec/Swarm_spec.md:9`, echoed in Cluster_spec/Radio_spec): **"Cluster_spec is HOW IT RUNS,
  Radio_spec is WHAT STREAMS, Swarm_spec is WHO'S ON IT."** So "Radiobuddies" names the **integration** of
   Swarm × Radio × Cluster — a thing with no card on the Credence board. Closest single word is **Swarm**,
    but Swarm is explicitly the *non-Radio* half (people, not the stream). Glosses (grep -a the specs):
- **Cluster** = how it runs (trust substrate + runner-flock above Peeroleum) `spec/Cluster_spec.md`.
- **Radio** = what streams (the music pipeline, §1-9) `spec/Radio_spec.md`.
- **Swarm** = who's on it (portable %Identity, %Pier contacts, signed Idzeug invites+grants) `Ghost/S/Swarm.g`.
- **Peeroleum** = the particle-only p2p transport spine everything stands on `Ghost/N/Peeroleum.g`.
- **Clustation** = the "who am I" identity/grid sublayer (mint/adopt the prepub a peer advertises).
- **Engage** = runner-engagement/lease ("an editor reserves a runner; the client drives it") + `to:<prepub>`.
- **MusuReplica** sits INSIDE Radio/Musu (paginated C** library sync across two Piers), well below the shebang.

**The `${pub}_N` multi-instance identity** (owner: editor at one address, a music node at `${pub}_2`, friends
 reach the music one; implies a protocol to locate which `_N` runs music): building blocks EXIST but for a
  DIFFERENT purpose. In `Ghost/S/Swarm.g:389-465` ("places" region, proven by SwarmSteal): `Swarm_address`,
   `Swarm_next_suffix` (next FREE suffix), `Swarm_sibling`, **`Swarm_take_role(ident, role)` with role ∈
    {music | encode | serve}** ("only one tab plays music"), `Swarm_steal_back`/note_theft; plus relay-side
     **`to:<prepub>` / `to:<prepub>_N`** verified dispatch (`spec/Cluster_spec.md:303-317`). BUT:
- suffixes are **collision-ordering + theft-defense**, NOT a deliberate role→address map (no editor=_1/music=_2
   convention); role is a separate session-local `%Peering.sc.role`.
- role/address/sibling husks are **stripped from every export** (`Swarm_protocol` omits them) and the sibling
   roster is **local Dexie-liveQuery only** ("our tabs on THIS browser"), never sent to a friend.
- **no friend-facing instance-discovery** exists — nothing lets a contact enumerate your `${pub}_N` and find the
   music one; `to:<prepub>` addresses the primary bound socket by identity only.
- the client half of `to:<prepub>` is unbuilt (relay accepts a signed `hello`; no peer emits it yet).
- **OPEN spec question** (`Swarm_spec.md:412`): is `<prepub>_N` the SAME key on a suffixed address, or an
   ephemeral per-place key vouched by the identity? Undecided — decide this before building Radiobuddies routing.

So Radiobuddies = give the un-named integration a home, and build the friend-facing "locate my music place"
 discovery on top of the existing `Swarm_take_role(role:music)` + `to:<prepub>_N` primitives. See
  [[bigqualand-aufheben]] (Sounditron is the Book that would run role:music).

**Owner's layer narrative (2026-07-07, verbatim in spirit):** *Swarm is the first thing you'd show
 someone about the Pier; Cluster is its PROTO SELF — an Identity that can use the relay without
  really being a Pier or anything about Radio; that intersects Peeroleum, which goes on to be the
   fullest networking gear you'd want underneath.* So the pedagogy order is Swarm (the showpiece)
    → Cluster (proto-identity) → Peeroleum (the deep gear), with Radio the experience on top.
     Same date: Radiobuddies declared **the MAIN conceptual spring** (not a mini-project —
      Radio_todo.md header reframed), Music_todo.md RENAMED → **Radio_todo.md** (the Radio*.md
       cluster), Credence restructured (Pere→Swarm→Musu→Voro up top, low-level in What:Puddle),
        and license granted to INNOVATE the generic Peering/Pier substrate — low-level proofs are
         a ladder, expect higher-level re-draws (Repli as the universal mover, mail wire → spine).

----
## merged from radiobuddies-regroup-handover.md

---
name: radiobuddies-regroup-handover
description: Radiobuddies = the named run-a-node+share-by-identity product; regroup = pull real software OUT of Ghost/Story/Musuation.g into family ghosts; brief = spec/Radiobuddies_handover.md
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

**Radiobuddies** is the owner's name for the previously-unnamed run-a-music-node + share-by-identity
 system (supersedes the "shebang has no name" note in [[radiobuddies-shebang-unnamed]]). Full
  continuation brief: `src/lib/O/spec/Radiobuddies_handover.md` (written 2026-07-05).

**The regroup thesis:** `Ghost/Story/*` is test-scaffolding ONLY, but `Ghost/Story/Musuation.g` (3812
 lines) has two slabs of REAL product software its own region comments confess — `//#region reality`
  (L28-299, the audio engine: Musu_synth/measure/radiostock/real_stream) and `//#region repli`
   (L2839-3266, the C** replication protocol). Destination = extract them to family homes
    (`Ghost/M/Sound.g` + `Ghost/N/Repli.g`), rename `Musu_`→family prefix, leave Musuation.g as pure
     scenarios. Precedent already done once: Voro_crush_scan moved Musuation.g→Ghost/V/Voro.g.

**The bomb:** nothing at runtime forces the split (methods mix onto H regardless of file), so it only
 happens if done deliberately. Guarded by gen-.go-before-CREDULER_GHOSTS + [[gen-crosswire-runner-dead]];
  do each slab in isolation, re-verify live per [[fight-back-on-core-changes]] + [[verify-via-live-runner]].

**PROGRESS (brief §5 = 3 ordered code steps, DON'T BATCH — a red run after step N must blame step N):**
 Step 1 **Sound** DONE (committed 7b5059e0; verbs renamed Musu_→Sound_). Step 2 **Repli** DONE +
  **COMMITTED by human 8dfae263** ("split Repli, etc"): `//#region repli` cut → `Ghost/N/Repli.g`,
   a CLEAN lift (verbs already `Repli_`-prefixed → NO rename/caller edits; Selection import moved
    with it; gen/N/Repli.go + CREDULER_GHOSTS enrollment all in HEAD). Step 3b **register on the map**
     DONE this session: hand-edited `wormhole/Ghost/Music/Ality/toc.snap` (the hand-authored overlay
      map, NOT Credence's Book list) — repointed the audio Points to Ghost/M/Sound.g (Sound_ names) +
       every Repli_ Point to Ghost/N/Repli.g, and ADDED a first-class `What:the replication spine` node
        (parallel to `What:the machine`=Radiola). Both extractions had left the map pointing the old
         Musuation.g home; now honest (validated: all 5 Sound_/21 Repli_ Points resolve, 0 stale).
 **LIVE GATE 2026-07-07: MusuReplica GREEN** on the live runner (owner-confirmed) — including the
  wire-fold `%see` restored via an all-but-one gate (`stuffed >= boxes.length - 1`; the last box's
   frames ride post_do → one beat late, diagnosed with a one-shot `w/%log`, see [[accept-drops-proof-in-entropy-zone]]).
    MusuReco green not separately confirmed. **STILL OWED:** **Step 3a Reduce** — retire redundant probes
     (DESTRUCTIVE, owner-judged, [[musu-test-consolidation]]). **NEXT DIRECTION (owner 2026-07-07):**
      Klepto mode = Radio_todo.md **§10** (see [[pier-reality-ideas]]) — heist-at-a-Pier mirror-everything;
       rung 2 (cohort) is the forcing function for 2-runner REAL Piers.

**Arena of invention (3 layers):** Book (born, one rung, disposable) → spine ghost (graduated, pure
 verbs, no %witnessed) → app/Sounditron (Layer 0, composes the spine, NO Book). Cohesion is NOT a
  mega-Book; it's the app standing on the spine + retiring redundant probes ([[musu-test-consolidation]]).

**Next besides the file regroup** (the product actually existing for a stranger): audio-plays-across-
 the-wire (reconstruct %audiochunk→PCM→Player), 2-runner real Pier multicast, and share-by-identity
  friend-facing DISCOVERY (Swarm.g has ${pub}_N blocks but no "who's online + sharing what").
