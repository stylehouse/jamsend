# Garden.g + Tyrant.g — the cabinetry & partying over the Peeroleum floor (design sketch)

*Two ghosts (the owner's call): **Tyrant.g** = the cabinetry — identity & trust → admission
 (ex-Tyranny); **Garden.g** = the partying — social cultivation (ex-Gardening). The earlier
  single-ghost name `Joinery`/`Covenant` is **rejected**. Neither `.g` exists yet — net-new.*

**The image (owner's):** Peeroleum is the *Linoleum on the floor* — the transport substrate you
 stand on but never see; a message crosses, acked, either carrier. Everything else is **cabinetry
  and partying over the top.** The *cabinetry* (**Tyrant.g**) is the built-in, load-bearing furniture
   — identity, trust, and the policy-gated door you're admitted through (M1+M2). The *partying*
    (**Garden.g**) is what happens once you're inside — introductions, engagements, the social graph
     living (M3).

A clean-room rebirth of **Tyranny** (identity & trust → Tyrant.g) + **Gardening** (social cultivation
 → Garden.g) on the Stuff|Housing platform, in stho. The legacy concepts are keepers — *prove who you
  are, apply trust, get admitted, then introduce and engage* — the gross language is not. Built **on
   top of the Peeroleum transport** (the floor), not beside it: we do not re-prove M0 (the emit/ack
    core), we *call* it.

Canon followed: `LakeTiles.g` (syntax), `LiesStore.svelte` (the fullest phased-`%req` architecture —
 the admission req is modelled on it), `Peeroleum_spec.md` (the transport we reuse — §4/§5/§7).
  Conceptual ancestors: `ghost/Gardening.svelte`, `ghost/Tyranny.svelte`. The Peeroleum handover's
   "Forward look" heading points here.

## The decision that frames this

**Clean-room, transport reused.** Peeroleum already carries a message verbatim over either
 carrier and acks it (`Peeroleum_send` → `Peeroleum_deliver` → `Peeroleum_take_ack`,
  outbox/inbox lifecycle, `rollup_faulty`, whittle). Tyrant.g/Garden.g emit *through* that seam
   and never touch a transport. So **M0 is reused, not rebuilt** — the first written minimum is
    M1 (Tyrant.g's trust).

The reused seam (the only Peeroleum surface these ghosts call):

```
&Peeroleum_send,w,{header:{type:<verb>, from, to, seq}}   // emit verbatim, any carrier, auto-acked
hear_<verb>(w, pier, frame) -> true | false               // a receive handler; false ⇒ %faulty
```

They add receive verbs to the inbox dispatch the way `hear_hello`/`hear_trust` already plug in;
 they own no carrier code. (The trust-everything seam they bolt onto is Peeroleum_spec §5.)

## The minima ladder

- **M0 — pure emit/ack core.** *Reused from Peeroleum, not written.*
- **M1 — message-abstract trust, Alice+Bob magically given.** Identities pre-provisioned (the
   `%Ud` is stamped, no meeting). Trust as a first-class exchange over given identities; every
    step a message, every message acked.
- **M2 — the meeting leg + policy-gated admission.** Alice and Bob must *meet* (introduction),
   *prove* identity, and **policies gate admission**: a `%req:join` whose `finished` is the
    conjunction of policy leaves. You are not "on the network" until that req is signed finished.
- **M3 — cultivation (later, Garden.g).** Gardening's `OverPiering`/`Engagements`/pruning: tending
   many Piers, retiring dead ones. Out of scope for this sketch; noted so the shapes leave room.

---

## M1 — trust over given identities

**Given (magic provisioning).** Skip the meeting: each side starts with the other's identity
 already known. Modelled on Peeroleum's `%Ud` (the proven identity that survives resets).

```
A:Alice/w:Tyrant
  %me,id:alice                       my own identity (given)
  Peering,name:alice
    Pier,pub:bob                     a Pier toward Bob
      %Ud,id:bob                     ← given: Bob's identity pre-stamped (no meeting in M1)
      %trust                         the trust state this sketch grows
```

**Trust as an acked exchange.** Trust is its own small `%req`, leaves driven by messages, each
 leaf settling when its message round-trips (the ack is what advances it). The shape mirrors the
  handshake's maz tree but the vocabulary is trust, not hello:

```
Pier oai %req:trust,eternal
    // maz leaves — each says one message and settles on its ack/echo
    req oai %req:vouch,maz:3            // "I extend trust to you" — emit type:vouch
    req oai %req:heard_vouch,maz:5      // their vouch landed in my inbox
    req oai %req:grant,maz:7            // both vouched ⇒ stamp %trust,grants on the Pier
```

stho for the say/hear pair (reusing the Peeroleum send seam, LakeTiles `&` + `n%such`):

```
say_vouch(w, pier):
    let proto = pier oai protocol
    let vouch = proto oai vouch
    if vouch%said
        return
    let me = pier.c.up%name
    let seq = this.Pier_next_seq(pier)
    vouch i %said,seq:$seq
    &Peeroleum_send,w,{header:{type:'vouch', from:$me, to:pier%pub, seq:$seq}}

// a received vouch: record it, and once we have BOTH directions, grant.
hear_vouch(w, pier, frame):
    pier oai protocol/vouch i %heard
    if (pier o protocol/vouch%said) && (pier o protocol/vouch%heard)
        pier oai %trust...%grants:full
    return true
```

**What M1 witnesses.** `Pier%trust,grants:full` on both sides — reached purely by acked
 messages over given identities. No meeting, no proof.

**What's new over Peeroleum's `say_trust`/`hear_trust`.** The current spine treats trust as one
 trivial leaf of the handshake. M1 makes trust a *first-class bidirectional exchange that
  settles on acks* and yields an explicit `%trust,grants` particle — the thing M2's policy reads.

---

## M2 — the meeting leg + policy-gated admission

Now nothing is given. Alice and Bob must **meet**, **prove**, and be **admitted**.

### Meeting (Gardening, reborn)

An introduction stands up a Pier that did not exist — either a rendezvous/introducer hands over
 a contact, or a side dials an address. The pure form is a `%req:meet` that ends with a Pier
  bearing an *unverified* counterpart (no `%Ud` yet — that's M2's whole point):

```
Peering oai %req:meet,to:bob
    req i %dialing,to:bob
    // on contact: a Pier with a CLAIMED, not-yet-proven, identity
    req oai %req:met,maz:5
        Peering i Pier,pub:bob/%claim,id:bob   // claim only; %Ud is withheld until proven
```

### Proof (Tyranny, reborn)

Identity proof distilled from `Idvoyage`/`Idzeug`: a claim, a challenge, a proof, a verdict.
 The proven identity *becomes* the `%Ud` (so M1's trust can then run on top):

```
Pier oai %req:prove,eternal
    req oai %req:challenge,maz:3       // emit type:challenge,nonce
    req oai %req:proof,maz:5           // their signed proof lands in inbox
    req oai %req:verify,maz:7          // verify ⇒ promote %claim to %Ud, else %faulty

hear_proof(w, pier, frame):
    let h = frame.header
    if !this.Tyrant_verify(pier, h)
        return false                   // ⇒ inbox stamps %error ⇒ %faulty (the reject path, reused)
    pier rm %claim
    pier oai %Ud...%id:$(h.id)         // proven identity, survives resets
    return true
```

`Tyrant_verify` is the one place real crypto eventually lands; under the mock it is the
 Peeroleum `startsWith`-style check (see `hear_hello`). Corruption tests (Peregrination step 7,
  the meddle hook) fall straight out of this `false` path — same machinery.

### Admission (the elegant core — a policy-gated `%req`)

This is the sentence you wanted nailed: *"policies apply before your `%req` is signed into a
 finished state enough to let you on the network."* Admission is **one `%req:join` whose
  `finished` is the AND of its policy leaves** — exactly the LiesStore phased-`%req` shape. The
   req cannot settle until every policy passes; settling it *is* being on the network.

```
w oai %req:join,eternal
    // each policy is a leaf that finishes only when its condition is met.
    //  the parent %req:join reaches finished ⇔ every leaf finished (the maz AND).
    req oai %req:policy,kind:met,maz:3          // we actually met (Pier exists)
    req oai %req:policy,kind:proven,maz:5       // identity proven (%Ud present)
    req oai %req:policy,kind:trusted,maz:7      // trust granted (M1 ran, %trust,grants)
    req oai %req:policy,kind:introduced,maz:9   // enough vouchers (cultivation hook, M3)
    // the gate: when all policy leaves finished, sign and admit.
    req oai %req:admit,maz:11
        w oai %member...%signed:1                // ← "on the network", signed finished state
```

A policy leaf's do_fn is a pure read of the particles the earlier minima produced:

```
policy_proven(w, req):
    let pier = w o Peering/Pier
    if pier%Ud
        req i %ok          // this policy passes; its finished rolls up to %req:join
```

**What M2 witnesses.** `w%member,signed` reached only after meet → prove → trust → admit, with
 any single failed policy leaving `%req:join` un-finished (you stay off the network) — and a
  corrupt proof leaving `%faulty` instead. The signed `%member` is the readable end state.

---

## Witnessing (the Book)

Same machinery as Peregrination (`Story/Peregrination.g`, the Lake_drive step dispatch): a
 `Tyrant` Book whose inner steps each fire one minimum's setup once and poll a witness:

```
step 2  M1: given Alice+Bob, run %req:trust ⇒ witnessed:trust (%trust,grants both sides)
step 3  M2 meet:   %req:meet ⇒ a Pier with a %claim (no %Ud yet)
step 4  M2 prove:  %req:prove ⇒ %claim promoted to %Ud (or %faulty on a meddled proof)
step 5  M2 admit:  all policy leaves finish ⇒ %req:join finished ⇒ w%member,signed
```

Each step is a `step=N,dige` line in `toc.snap` (lie diges until a run records them, per
 [[story-step-lines-drive-steps]]); the witness is a `%witnessed:<phase>` particle so it shows
  in the snap diff like everything else.

## Open decisions

1. **Name — RESOLVED.** Two ghosts: **Tyrant.g** (cabinetry: identity/trust/admission, M1+M2) and
    **Garden.g** (partying: cultivation, M3). `Joinery`/`Covenant`/`Salon` are dead.
2. **One ghost or two — RESOLVED to two** (the owner's call). The original sketch leaned *one*
    cabinetry ghost with the party sprouting later; the owner split it cleanly along the
     cabinetry/partying line — Tyrant.g now, Garden.g when cultivation (M3) pulls. M1+M2 are
      Tyrant.g; the seam between them is just which `hear_<verb>`/`%req:*` each owns.
3. **Where trust sits relative to the handshake** — does Tyrant.g's `%req:trust` *replace*
    Peeroleum's `say_trust`/`hear_trust` leaf, or layer above a still-minimal handshake? Sketch
     assumes layer-above (the handshake stays hello-only; trust graduates to Tyrant.g).
4. **`Tyrant_verify` under the mock** — reuse Peeroleum's `startsWith` shim, or stand up a
    toy sign/verify now so the proof leg is real (and corruption is signature- not key-shaped).
5. **Policy set is open** — `met/proven/trusted/introduced` are a starting four; the whole point
    of the `%req:join` shape is that policies are *data leaves*, so the set can grow without
     touching the gate.
