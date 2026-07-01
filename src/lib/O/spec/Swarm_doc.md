# Swarm_doc — the p2p social side of jamsend

The non-Radio half of jamsend: the **people** and the social fabric between them — identities, presence,
 what-you-offer, following, sharing. Where `Radio_spec` is the *stream* and `Cluster_spec` is the *machine*,
  this is the *society*. A p2p social medium whose richest payload happens to be Radio, but whose substrate
   is just identities finding each other and sharing snapped state over the same edges.

This is a **starting doc**: the identity substrate (§2–§4) is worked out; the social fabric (§6) is
 scaffolding to bring the non-Radio features into. Mark **[now]** for the current code, **[want]** for the
  proposed direction — much of the identity story is a *want* today (identity currently hides in Dexie).

Neighbours: `Cluster_spec.md` (trust substrate, runner flock, relay — the infra this rides on),
 `Radio_spec.md` (the streaming platform), `Cluster_runner_handover.md` (`%HostedIdentity`/`%Runner`, the
  live registry), `Keeping_spec.md` + `Interest.md` (acceptance / attention — where the social provenance lands).

---

## 1. The one idea

**A person is a portable identity-particle; the swarm is those identities finding each other and sharing
 snapped state.** Every social feature is a facet of that:

- an **identity** is a `%Identity` particle you *own* — it lives on your disk, not in a browser;
- a **session** is one place that identity is currently live (a tab, a device) — addressable on its own;
- a **capability** is something an identity *offers* the swarm (audio, disk, compute), advertised;
- **presence** is which identities are reachable right now, and what they're offering;
- **sharing / following** is snapped `C**` state flowing along the cheapest edges (the same edges Radio uses).

So "build the social side" is not N features; it is *identities + edges + snapped state*, and each section
 below is a lens on it — the same move Radio_spec makes for audio.

---

## 2. Identity is a portable particle, not a browser secret

**[now]** An identity is a `%Identity` (Clustation) with its keypair, persisted to the Dexie `identities`
 Thang and made active; `?I=<tag>` mints or resumes one, the channel signs the relay `hello` as it, a runner
  advertises as it. See `Auto.svelte` (`Clustation_ensure_identity`/`Clustation_concrete`) and the
   [[stho]]-adjacent Thang machinery.

**[want]** Give it an **encodable form on the user's own disk** — while *keeping* Dexie. The axis that matters
 is not *where* it's stored (Dexie and localStorage are equally origin-bound, un-shareable across a browser or
  device) but **encodability**: a particle is enLine-able, snappable, copyable over the wire and to disk; a
   Dexie/local blob dead-ends. So the identity gets a **snapped C-tree on disk** via the Wormhole —

```
<music-collection>/.jamsend/account/<prepub>/toc.snap
```

— as the durable, portable, inspectable copy, with **Dexie as the working store**. The owner's rule
 (2026-07-01): **Dexie AND disk — stream Dexie→disk continuously; unless there's nothing in Dexie, in which
  case seed Dexie from disk.** So:

- **Dexie** is always-available and synchronous — it's where the identity lives at *first boot, before any share
   is open*. This dissolves the chicken-and-egg: the identity exists before disk does.
- **disk** is the write-through mirror + the seed a fresh browser imports when its Dexie is empty.
- this mirrors the Wormhole's own **seed/scratch** split (`WormholeOpfs`): a durable seed you can copy/back-up,
   a live scratch you actually work in.

Then the identity is **portable** (copy the account tree → it moves), **inspectable** (it's a snap), **backed
 up** (rides the user's own data), and no longer a Dexie-only anomaly — while keeping Dexie's pre-share
  availability. The **secret key** sits in the user's own file on their own disk — the same trust posture as the
   FSA share they already opened (`Cluster_spec §2`: a browser may hold a key on a trusted origin). The account
    tree holds more than the key: friendly name, declared capabilities (§4), follows, settings.

> The disk copy is a **snap**, not a raw Dexie export — that's what lets the *same* representation double as a
>  shareable contact (its public subtree over the relay), a backup, and a move to another device. Dexie is the
>   fast local copy that streams into it, not a parallel format.

---

## 3. Identity ≠ Address — the multi-place problem

A portable identity can be open in **N places at once** (two tabs, a laptop and a phone). Today the identity's
 prepub *is* its relay address: the `hello` binds `prepubOf(pub) → socket`. So N live places = N sockets
  binding the **same** prepub, and the relay's `bind` is a Set — `to:<prepub>` fans out to **all N**. That is
   the "runs going to both runners" double-delivery bug, one layer up. (`relay-test.ts` now guards the runner
    version of this contract; the identity version needs the same care.)

**Resolution — separate the two things that got conflated:**

- an **identity** is durable, portable, who-you-are — it is *not* a routing handle;
- a **session** is one live place, with its **own** relay address (an ephemeral per-session key), **vouched**
   by the identity (the durable key signs the session's `hello`, so the relay knows session S belongs to identity I).

Then addressing is deliberate, not accidental:

- `to:<session>` → exactly one place (a directed rungo, a become_book, a DM to the tab you're at);
- `to:<identity>` → **all** my live sessions (a broadcast you *chose* — a notification to every place I'm signed in).

This is precisely the runner **role-bucket** (`to:'runner'` = all) vs **per-runner-prepub** (`to:<pub>` = one)
 split from `Cluster_spec §3.2`, and what §3.1's "fork identity at the tab, not the profile" is reaching toward.
  The multi-place collision isn't a wall — it's the signal that *identity* and *address* are different objects.

---

## 4. Capability + presence — what an identity offers the swarm

An identity **offers** things: audio playback, disk to proxy, compute to run a Book. These are the social
 currency — "who can do what, and who's up right now."

- A **capability** is a flag on the `%Identity` (`audio`, later `disk`, `compute`, …). Because it's on the
   identity particle, it is declared once and travels with the identity (§2), not re-set per browser.
- It reaches the swarm on the **existing** presence beacon: `Lies_advertise` already emits off the active
   identity and `Lies_advertise_recv` already folds it into `%HostedIdentity` (the durable directory) +
    `%Runner` (live presence). **Advertise a `caps` map, not a hand-added field** — the beacon body is already
     a hand-kept list (`friendly, ready, book, engaged`) whose own comment wants a "dige-sync that collapses
      this field list"; a `caps` map is that collapse for capabilities. One write in recv, any number of caps,
       no signature churn. (First cut, agreed with the Radio agent 2026-07-01: a **flat `audio` facet** beside
        `ready/book/engaged` — matches the current rail exactly; the `caps` map is the collapse to make once the
         dige-sync lands, so a second capability doesn't re-open the beacon.)
- **Split durable capability from live fact**, reusing the split the roster already has:
  - `%HostedIdentity.caps` — *can* do audio (durable, declared, part of the account);
  - `%Runner` live state — audio is *ready right now* (ephemeral, like `last_heard`/`ready`, sourced from the
     runtime AudioContext gate).
  "hasAudioContext" conflates the two; keep them apart and each slots into an existing shelf.

**Browser gestures at the boundary, not per-load.** An `AudioContext` needs *a* user gesture per page load to
 leave "suspended" — but that is a browser artifact to dissolve at the edge, not a ritual the capability model
  carries:

- **human tab** — *any* interaction satisfies it; if a person is using the tab, it's already granted. No dedicated ceremony.
- **headless audio runner** — launch Chrome with `--autoplay-policy=no-user-gesture-required` (in the flock
   launcher / `bot.js`). No gesture, ever.

So "does this identity provide audio" is a clean declared capability; the gesture is handled once at launch or
 absorbed by normal use — never an every-load tap.

---

## 5. The account on disk

`<music-collection>/.jamsend/account/<prepub>/` is the identity's own tree. First cut of what it holds:

- the **keypair** (secret local to the user's disk) + the friendly name;
- declared **capabilities** (§4);
- **follows / contacts** — other identities' prepubs (+ their last-known friendly, relay hints);
- **settings** the identity carries between places.

It snaps like any `toc.snap`; a second device *is* this identity by opening the same account tree (then §3
 hands it a distinct session address). A contact is shared by handing over the *public* subtree (prepub +
  friendly + caps), never the key.

---

## 6. The social fabric — [scaffold] to bring the non-Radio side into

The features that make it *social media*, to spec as they come over. Sketches, not commitments:

- **Follow / subscribe** — an account holds a set of followed prepubs; presence + their shared feeds resolve
   against it. The roster (`%HostedIdentity`/`%Runner`) is the online-now view; follows are the durable graph.
- **Feed / sharing** — snapped `C**` an identity publishes; it flows along the cheapest edges (Radio's mesh,
   `Radio_spec §1`) — the social payload and the audio payload ride the same transport.
- **Acceptance / provenance** — *who* shared a thing and *whether I accept it* is the `Keep`/`Interest`
   layer (`Keeping_spec`, `Interest.md`: ACCEPT = who/what/Interest-provenance). The social graph is where that
    provenance is rooted — a share carries its sharer's identity, and acceptance is an identity-level judgement.
- **Presence as social signal** — "these people I follow are up, and here's what they're offering" is §4's
   registry read through §6's follow set.
- **DMs / addressed social messages** — `to:<session>` / `to:<identity>` (§3) is already the primitive.

---

## 7. Open decisions

- **Session key lifetime** — ephemeral per-tab, or a short-lived cert the identity re-issues? (§3)
- **Account-tree conflict** — the Dexie↔disk stream (§2) and the same-account-on-two-devices case are the same
   `C**` merge/`EntropyArrest` question the rest of the system has. What reconciles when Dexie *and* disk are both
    non-empty and diverge (last-write-wins on `toc.snap`? a real merge?)? Does the account tree get its own policy?
- **Where the account tree mounts** — always in the music collection, or a configurable Wormhole path? (The
   pre-share chicken-and-egg is RESOLVED by §2's Dexie-AND-disk rule: Dexie holds the identity before any disk
    exists, then streams out when a share opens. Remaining: the mount path, and the divergence case above.)
- **Relay knowledge of `to:<identity>`** — does the relay learn the identity→sessions mapping (so it can
   fan out an identity-addressed frame), or does the sender enumerate sessions from the roster? (§3)
- **Capability revocation / trust** — a declared cap is a claim; does anything verify it, or is it advisory
   until a run proves it? (ties to `Cluster_spec §2.8`: membership *is* the permission — caps may be the same.)

---

*Status: framing + the identity substrate (§2–§4) worked out; §6 is scaffolding. The identity-on-disk and
 identity≠address moves are **[want]**, not built — current identity lives in the Dexie `identities` Thang.*
