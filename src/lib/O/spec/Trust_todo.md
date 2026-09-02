# Trust_todo.md — the protocol beneath the protocols

A **capture doc, not yet a plan** (the Atheory pattern — an itch given an address). The owner
 reached for this while venting about the Adopt/Ferry ceremony, 2026-08-28:

- *"this powwow with the Adopt protocol needs to live under the Trust protocol… and all our
   protocols need to be secured by the Trust that enables them, somehow. are we within a
    `Grant:Adopt` role or something?"*
- *"I don't really care how elegant that is for right now actually, just venting, maybe put it
   somewhere."*

## 0. What this is about

One sentence: **every protocol we run (Music sharing, Adopt/Ferry, Heist, the invite ledger) is
 authorised by a grant, and the granting itself — the consent, the SAS match, the "yes, I trust
  this" — is a protocol in its own right that today is scattered and re-invented per feature.**
   The vent asks: name it. Make **Trust** the substrate every other protocol sits on, so a
    feature says *"I run under `Grant:Music`"* / *"I run under `Grant:Adopt`"* the way it already
     says which `%Feature` it carries — and the consent ceremony (popup + SAS emojis + the signed
      grant that results) is ONE reusable machine, not a thing each protocol grows its own crooked
       version of.

The tell that it wants naming: the **Ferry** path (the live device-link) SUPERSEDED the **Adopt**
 path (`Division_todo` §0) and in doing so **lost the mutual consent + the EmojiConfirm SAS** that
  Adopt already had (`Swarm_adopt_sas_land`/`_consent`, "shows on BOTH screens to catch a relay
   MITM"). Two ceremonies, one of them silently weaker — because the trust step was never a shared
    protocol, just code each side happened to carry. That's the disease this doc names.

## The `Grant:Adopt` musing

The owner's own half-question — *"are we within a `Grant:Adopt` role or something?"* — points at the
 shape. `Division_todo` already models a body's **Post** as a cross-signed grant (`%Grant:MyCave`,
  `%Grant:MyCaptain`) rather than a self-chosen tag; **Trust** would generalise that: the RIGHT to
   run a protocol with someone is itself a grant, minted by a consent ceremony, revocable by
    `%NotGrant`, and gated at USE the way `Swarm_pier_live(pier, 'Music')` already gates the music
     dial. "Am I allowed to ferry my soul to you?" becomes the same question as "am I allowed to
      serve you music?" — a live grant check, not a bespoke handshake.

## Its neighbours (so this doesn't grow in isolation)

- **`Crew_todo.md`** (absorbed `Division_todo`, now `spec/history/`) — the crew ceremony + grant model
   live here. Trust is
   the layer *beneath* it: Division is one protocol that Trust would secure. The `#fc`→nonce
    decision (§0 there — "eed is the security control point") is already a Trust-shaped ruling:
     the human at the granting device IS the trust anchor, so the paranoid machine-secret is fluff.
- **`Focus_todo.md` / `Atheory_todo.md`** — the toplevel's *attention* and *loading* halves. Trust
   is a third cross-cutting substrate the rebuilt toplevel might own: who's allowed, who's shown,
    what's loaded.

## Not yet

No design here — this is the itch's address. When it starts: inventory every place a consent /
 grant / SAS / "do you trust this" decision is made (Adopt, Ferry, friend-invite redeem, Captain
  mint, the Heist authz), see how much is already the same shape (`mint_grant` + `Swarm_pier_live`
   + the SAS row), and only then propose whether **Trust** is a real new register or just the
    honest name for what `%Grant` + the ceremony already are.

## First concrete step it implies (owed regardless of the big rename)

**Restore consent + SAS to the Ferry path.** Independent of whether "Trust" becomes a register, the
 ferry today auto-fires on seal with no grantor approval and no emoji match — strictly weaker than
  the Adopt ceremony it replaced. Re-attaching the grantor-consent popup (*"device X wants to
   become a Cave of your account — approve?"*) and the 3-glyph SAS is the first payment on this
    debt, and it doubles as the fix for *"eed has no idea / no trace on eed side"*. Tracked as the
     ceremony redesign in `Division_todo` §0 NEXT MOVES.
