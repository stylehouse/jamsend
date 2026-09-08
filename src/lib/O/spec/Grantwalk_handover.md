# Grantwalk_handover.md — the fork: a Grant moving among Crew, and Heisting beside it

A **continuation brief**, not a topic doc. Written 2026-09-08 by the app|infra session so that the
 fork starts from the gap rather than from a census. Its living docs are `Crew_todo.md` (membership
  words) and `SoundPooling_todo.md` (the heist circuit); read this to know where to stand, then read
   those. The owner's framing: *"I need to verify mobility of a Grant amongst Crew, and Heisting."*

## 1. THE DESTINATION

**A grant must be able to move between bodies of one soul and still be true after a reload.**
 Today it moves, and it is Book-proven that it moves. What is NOT proven is that it *stays* moved.

## 2. THE BOMB — read this before you touch the helm

`Crew_todo §0` says it in its own words, and it is the thing that detonates if the fork does not know it:

> the helm path is **Book-proven and NOT live-walked** — treat it as design-complete, implementation-owed.

The specific hole: a body promoted by a ledger flip signs as the new Captain, but **nothing re-homes
 the stash or mints it a fresh key**. So the flip is true in memory and false on disk, and

    a reload after a hand-over RESURRECTS THE OLD FOUNDER.

That is why a green SwarmHelm is not evidence here. The Book never reloads, and the defect lives
 exactly in the seam a reload crosses. **A Book cannot gate this one.** The gate is a live walk with
  a deliberate reload in the middle — which is the whole reason this is a fork and not a Book run.

Named and owed in the same section: the **station re-dial** and the **stash/account re-home** after a
 founder stands down, and a mate's own secret. None of those are written yet.

Second, smaller tripwire, already caught once and worth not re-learning: a `%Pier` caches the last
 accepted voucher signature at `pier.c.voucher_ok`, and **a voucher is per-ERA, not per-frame** — so a
  membership change that does not clear that cache lets an ejected body keep walking through the door.
   SwarmHelm beat 3 is that case. Any grant-mobility work must ask whether it invalidates the cache.

Third: **a second Captain is invisible to `Swarm_note_theft`.** The theft tripwire does not fire on
 the one case grant mobility can actually create. If the fork makes hand-over easier, it widens that
  blindness — deal with it in the same pass or write down that you did not.

## 3. WHAT IS ACTUALLY SOLID UNDER YOU

Do not re-derive these; they landed and are gated (`Crew_todo §0.0`, 2026-09-03):

- Keys are `/Crew` particles; the ledger travels (eject · helm · resume).
- `Grant:Crew` from the Captain IS membership. The `%Body` roster is a **routing cache, never
   membership** — a Cave once screamed theft at its own Captain because something read the roster.
- Caves CARRY the soul key (held, not wielded); the Captain is the mutex wielder; recovery is
   activating the copy.
- Books green at caveat 0: SwarmBody (23), SwarmSpread, SwarmHelm, SwarmStaple, InvWalk, InvFerry.
- The adopt road is DELETED. Anything describing adoption is history.

## 4. THE NEXT MOVE, IN ORDER

1. **Live-walk the helm with a reload in the middle.** Two tabs, one soul. Hand over, reload the
    promoted body, then ask who the Captain is. Expect the old founder. Capture what the stash holds
     at that moment — that is the evidence the fix is built against.
2. **Re-home the stash on promotion** (and decide: fresh key, or re-home the existing one? `Crew_todo`
    leaves this open, and it is the fork's first real ruling).
3. **Station re-dial after a stand-down.**
4. **Then re-run SwarmHelm** — it should still pass, and if the fix is right it now means something.

## 5. HEISTING, BESIDE IT

Two open items, both from `SoundPooling_todo`, both small and both about *who said so*:

- **`:640` — nothing binds a reach's `by` to the frame's actual sender.** The friend arm takes the
   claim at face value. This is the same family as the grant question: an assertion about identity
    that no one checks against the wire. Worth doing in the same head-space.
- **`:620` — a phone is owed a pools home.** `%Pools` lives on the live self's identity and the
   account snap carries it; a phone has no folder, so the shelf dies on reload. See the four durable
    homes ruling — a phone's only home is the House stash, and `Swarm_restash_all` is its whole surface.

The bytes themselves are FINE as of 2026-09-08: eed pulls at ~300KB/s sustained after the twin-record
 fix. Do not go looking for a transport bug; there isn't one.

## 6. WHAT THIS FORK SHOULD NOT DO

- **The `%Card` migration.** Ruled and unblocked (`Fallen_out_of_mind §2.9.1`), planned, and
   deliberately NOT started — a describe's mint also crosses the WIRE (`Heist_rummage_answer` →
    `Repli_offer` ships the mainkey in the line), so it needs a tolerant reader landed on both ends
     first. It is app-branch work and it is written down. Leave it.
- Anything in `src/lib/L/`, `Lies.svelte`, Atlas or Lagoon — the code|metaphysics branch is live there.
- Committing. Never. The human reviews the diff and writes the message.
