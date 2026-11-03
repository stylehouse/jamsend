# Station — a flock tuned to a few live Records, served from disk

**Status: an imagination ledger, born 2026-10-28, filed 2026-11-03.** Nothing here is built. It is the twin of
 `Radio_future.md`: that doc asks what listening could *feel* like, this one asks how one box *serves* a crowd. It
  sits under Radio's "Developing" shelf (`Radio_todo.md` §0.e) until it earns a todo of its own.

---

## 0. What to get on with next

Nothing is owed yet. When this wakes up, the first rung is **the schedule** (§2.1): a `%Station` holding a
 playlist with start times, and a Book proving that two listeners joining at different wall-clock moments land on
  the same `seq` with no per-listener state. No wire, no cache: pure arithmetic over the stock that already exists.

---

## 1. What the owner asked (verbatim, kept)

*2026-10-28:* "the tracks could begin in the non-beginning... a flock of listeners could be forced into a small set
 of "live" Records, mirroring how radio stations themselves only play one thing in real time, but with the problem of
  serving a huge flock of people pecking at a music collection independently, but serving it all from disk (io bound)
   over the network (also io bound, but we might not look at WebRTC mesh BS again yet... or maybe we should... maybe
    just a third party relay somewhere else they can run traffic through?"

---

## 2. The shape

### 2.1 A live Record is a schedule, not a stream

A station is a playlist with start times. Any listener computes where it is from the clock:
 `seq = floor((now − started_at) / seg_secs)`. The server keeps no per-listener cursor. Joining mid-track is free:
  the stock is already cut into independently decodable ~2s Opus segments *because* "playback starts in the middle
   more often than not" (`Radio_todo.md` §1.2, decided 2026-07-07).

This is the cheaper cousin of the **live edge** (`Radio_todo.md` §1.2, §9.4: "one chained continuous encode you join
 and follow"): a schedule over pre-cut segments needs no continuous encode at all.

### 2.2 Herding is the scheduler's real job

- **Live listeners** cost one disk read per station, and the page cache keeps hot chunks in RAM — so they cost only uplink.
- **Pecking** (my own track, my own position) is the long tail that actually hits disk.

So the scheduler herds:
- a peck can **join a station's queue** — "on in 4 minutes, with everyone";
- three pecks at one album **become a station**;
- **K** (the count of live stations) breathes with load;
- under uplink pressure a peck may get the preview encode (the cheap one) rather than the stream.

### 2.3 The numbers

At 96 kbps, 1000 listeners ≈ 100 Mbit uplink. **Network gives out long before disk does**, once most of the flock is
 on live stations. Disk only matters for pecks.

### 2.4 The third-party relay — the trap and the cheap win

⚠ **TURN is the wrong relay.** It forwards per pair; it saves nothing on fan-out.

The cheap win: chunks are content-addressed `(enid, seq)` — immutable — so serve them as **immutable HTTP URLs** behind
 any dumb cache (the Caddy already in front of djamsend, a $5 VPS with nginx, a CDN). The box serves each chunk once,
  the flock hits the cache, and the relay websocket carries only control.

The catch is **grants**: a cache can't check them. Either short-lived signed URLs, or accept that a station's chunks
 are readable by whoever's tuned in — which matches the standing ferry posture ("frames signed but relay-readable;
  accepted").

### 2.5 The mesh, later

A live station makes the WebRTC mesh *easier*: everyone wants the same `seq` at the same moment (the PPLive shape),
 so advertise/discover collapses to "who's a segment ahead of me". `Radio_multicast_todo.md` is that design; park it
  behind the HTTP cache.

---

## 3. Seeds already in the tree (don't re-derive)

| where | what |
|---|---|
| `Radio_todo.md` §1.2 | why segments are independent: mid-track entry is the common case |
| `Radio_todo.md` §1.2 / §9.4 | the live edge — a third mode, set aside "for later" |
| `Radio_todo.md` §10 | klepto broadcast: one disk sweep → `@channel`, latecomers tune in live then backfill 1:1; the cafe tree (same public IP → LAN edges) |
| `Radio_multicast_todo.md` | the swarm: advertise held chunks, discover a nearer holder, serve over a data channel; the per-chunk hash decision |
| `Radio_spec.md` stage 8–9 | Mesh and Stretch: cross the relay once, then fan out |
| `Daemon_todo.md` | jamserve, the resident body that would *be* the station |

---

## 4. Open — for the owner when it wakes

- Is a station a **person's** act (a DJ, a friend's radio broadcast) or the **server's** herd (K channels it runs to
   spare the uplink)? Probably both; which first?
- Signed URLs, or tuned-in = readable?
- Where does the cache live — on the daemon's host, or genuinely someone else's box?
