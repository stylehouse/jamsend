# Pier_todo.md — distinguishing the KINDS of Pier (friends vs our own bodies)

A **capture doc** (the Atheory pattern — an itch given an address). Owner, 2026-08-29:
*"push a todo for distinguishing types of Pier to include our other bodies."*

## 0. What this is about

A `%Pier` under a `%Peering` is currently drawn as one thing — a **friend** — but it isn't one
 thing. The grant it bears says what it IS, and there are (at least) three kinds:

- **A friend** — `%Grant:Music` (someone else's soul you share music with). The Door's real roster.
- **One of your OWN bodies** — `%Grant:MyCave` / `%Grant:MyCaptain` (a device you Linked; a Cave or
   Captain of your *own* soul, per `Division_todo`). NOT a stranger — it's you, on another machine.
- **(future) other Post piers** — as Division grows Posts beyond Cave/Captain, each is its own kind.

Today the pier list conflates them. The only distinction so far is a cosmetic **🔗 marker** on a
 MyCave pier in `DoorFace` (added 2026-08-28, so a Cave doesn't read as a stranger — the *"wtf it
  grants Music?"* confusion). That's a band-aid, not a model. The owner wants the KIND to be a
   first-class thing the UI groups and labels: **"my friends"** vs **"my other devices / bodies"**.

## Where the truth already is

`Swarm_pier_live(pier, feature)` already reads the grant by feature (`'Music'` vs `'MyCave'`), and
 `Division_todo` models a body's Post AS its cross-signed grant (`%Grant:My<Post>`). So the kind of
  a pier is **derivable now** from the grants it holds — no new state needed, just a classifier:
   `pier_kind(pier) → 'friend' | 'body:Cave' | 'body:Captain' | …`. The Charter (`Division_todo`
    §THE WELD) is the authority for which of your bodies plays which Post.

## Not yet (design owed)

- A `pier_kind` classifier + the Door grouping it into sections ("friends" / "your devices").
- Does a body-pier belong in the Door pier list at all, or in its own surface (a "your devices"
   panel)? The owner already split the *Link ceremony* out of the pier list into the Link cell — the
    settled Caves may want their own quiet home too, not the friends roster.
- How this meets the Charter: a friend sees your bodies via the Charter (Post→address); YOU see your
   own bodies via your MyCave/MyCaptain piers. One classifier should serve both reads.
- Presence: a friend pier pulses (heard_at); does a body-pier pulse the same way, or is its liveness
   the Charter + the transport's ground truth (`Division_todo` ROUTING — no liveness cache)?

## Neighbours

- **`Division_todo.md`** — the Post-as-grant model + the Cave/Captain bodies this must distinguish.
- **`DoorFace.svelte`** — the current pier list + the 🔗 band-aid; where the grouping would land.
- **`Trust_todo.md`** — "which grant a pier bears" is the same question Trust asks of every protocol.
