# Tend_todo — asking a box to do things: one signed call, any door

**Status: DESIGN + BUILD SPEC, nothing built (2026-10-13).** Written to be implemented rung by rung by a Sonnet
 session; each rung lists its files, functions, shapes and its proof. The grant's name is **open**: "Tend" throughout,
  rename in one sweep if the owner picks another (§9).

---

## 0. What to get on with next

- **T0** (§6): move the daemon's HTTP routes into a verb registry behind one dispatcher. No behaviour change, and no
   Book can see it. Start here.
- Then **T1 → T2** (the signed call over HTTP, plus a CLI). They're independent of the wire work in `Trust_audit_handover.md`.
- **T3** (the wire door) after T2 has run for a day. **T4** (the grant) and **T5** (the face) last.

---

## PART ONE — THE PICTURE 👤 (for people)

### 1. What this is

The music box that runs all day (the jamserve daemon) can be asked to do things: show its health, mint an invite,
 restock its shelf, slow down, restart. Today you ask over a little web server on port 9099 with a password everyone
  shares. Nobody can tell who asked, and you have to be on a network that can reach that port.

Tend replaces the password with **you**. Your identity in the app (the same key that makes you you to your friends)
 signs each request. The box checks the signature and checks you've been given permission, which is a grant it signed
  for you. It does what you asked and writes down that you asked. The request can arrive by web request, from a script,
   or as a message through the relay from any open jamsend tab. It doesn't matter which, because the trust is in the
    signed request itself, not in the road it took.

### 2. Scenes

- **At the shell.** You run `node scripts/tend.mjs status` on your laptop. It signs with your identity's key from a
   keyfile and posts to the box. The answer comes back as JSON.
- **From the app.** Your jamsend tab shows the box in the Door. Tap it and a small panel shows its CPU, memory, who's
   listening, and buttons for invite, restock and quieter. Each button sends a signed message through the relay. No port
    is open anywhere.
- **Letting a friend help.** You send Dara an invite that says "tend my box". Once she accepts, her own key can ask the
   box for status, or more if you allowed it. Take it back with one revoke and her next request is refused, by name.
- **"Who restarted it?"** The box keeps the last fifty things it was asked to change, with who asked and how.

---

## PART TWO — THE MACHINERY 🛠

### 3. The call envelope: the whole trust model is here

A call is ONE flat object of strings, signed with `signHeader` (`src/lib/cluster_trust.ts`: sorted-key canonical JSON,
 ed25519). Every field is a string, so it survives a round trip through a particle's `sc` byte for byte (the Grant.ts rule).

```
{ tend: '<verb>',            // the verb name — also the envelope's tell (a %Call row's mainkey value)
  args: '<json string>',     // verb arguments, JSON-encoded scalars; '{}' when none
  from: '<caller prepub16>', // who is asking (prepubOf(pub))
  pub:  '<caller pub64>',    // the full key that signed — verifyHeader is given [pub]
  to:   '<box prepub16>',    // WHICH box — a call is never valid at another box
  ts:   '<ms since epoch>',  // freshness
  seq:  '<integer>',         // per-caller monotone — the replay guard
  sign: '<hex>' }            // signHeader over every other key
```

**Verify** (`Tend_verify(env, me)` → `{ ok: true, who } | { ok: false, why }`), in this order. Each failure has its own word:
1. `bad_shape`: any field missing or not a string.
2. `not_for_me`: `env.to !== me.prepub`.
3. `bad_key`: `prepubOf(env.pub) !== env.from`.
4. `bad_signature`: `verifyHeader(env, [env.pub]) !== env.pub`.
5. `stale`: `|now − ts| > 60 000`.
6. `replayed`: `+seq <= hwm[from]`. The high-water mark is held per caller in `.c` (runtime only). It resets on restart,
    and the ts window covers the restart gap.

Then `hwm[from] = +seq`. Only after verify does anything look at the verb.

**Why sign the call and not the road.** The wire's sender proof today is a per-era voucher, which a relay could
 replay onto a forged body (see `Trust_audit_handover.md` §0.1). HTTP has no identity at all. A self-signed envelope is
  immune to both: it binds verb + args + target + time to one key. Every door becomes a dumb pipe, and the wire
   hardening can proceed on its own schedule.

### 4. Who may: principals and the grant

`Tend_may(who, need)`, where `need ∈ 'open' | 'read' | 'write'`:
- `open`: anyone, unsigned (only `status` today; keeps the current unauthenticated `/status`).
- **The box's own soul and crew.** `who` is the box identity's own soul pub, or holds a `Grant:Crew` by that soul. Gets
   `write`. Read through the existing `/Crew` rows: `Swarm_crew_grant` and the roster, as Swarm.g ~93–130 does.
- **A tender.** `who` holds a **`Grant:Tend`** with `by = the box identity's pub`, `for = who`, and optional
   `scope: 'read'|'write'` (default `read`), with NO matching `%NotGrant:Tend` (same by + for). Checked at use, never cached
    (the [[voucher-cache-outlives-revocation]] lesson).
   - **Where it lives:** on the box, under its `%Peering` → `%Pier` for that caller when one exists; else a `%Tenders`
      container under the box identity. One `%Grant:Tend` row per tender, via `grant_to_C` (`src/lib/O/Funk/Grant.ts:90`).
   - **Minting:** `mint_grant(boxKeys, tenderPub, 'Tend', { scope })` (Grant.ts:62).
   - **Revoking:** `mint_revoke(boxKeys, tenderPub, 'Tend')` (Grant.ts:108), landing as `%NotGrant:Tend`.
- **`operator@box`.** Not a key: the HTTP local door with the bootstrap token (§5.1). Gets `write`. It exists so the box
   owner at a shell, and the first boot before any grant, are never locked out.

Refusal words: `no_grant` · `scope_read_only` · `revoked`.

### 5. The doors: thin, and no verb ever sees one

#### 5.1 HTTP (`scripts/daemon/main.ts`, the existing server)
- `POST /tend` with the envelope as the JSON body: verify → may → dispatch. Response
   `{ ok, answer?, why? }` with status 200, or 403 for a refusal.
- `GET /tend/<verb>?args=<json>` with header `X-Daemon-Token`: the **operator door**. Principal `operator@box`. Allowed
   ONLY when the peer address is loopback or the docker bridge (`req.socket.remoteAddress` starts `127.` / `::1` /
    `172.17.`).
- **Every existing route stays, rewritten as a shim** onto the dispatcher with the operator principal: `/status`, `/c`,
   `/stop`, `/restock`, `/invite`, `/census`, `/profile`, `/tune`. Existing scripts and memory notes keep working.
- **`HOST` default** moves from `0.0.0.0` to `127.0.0.1` + the bridge. Public exposure only behind Caddy, and only `POST /tend`.

#### 5.2 The wire: a `tend` frame kind
- **Caller:** `Swarm_deliver(w, ident, boxPrepub, { kind: 'tend', env })`.
   **Box:** register `'tend'` in the hear funnel's kind list (Swarm.g ~2140, the `for (const kind of [...])
    w.c.on[kind] = hear` line), dispatching to `Tend_heard(w, ident, frame)`.
   **Reply:** `Swarm_deliver(w, ident, frame.env.from, { kind: 'tend_done', seq, tend, ok, answer?, why? })`, also
    registered.
- **No `Swarm_voucher_ok` dependence.** A tend frame is admitted on its OWN envelope signature, even from a non-friend
   (a tender need not be a friend). So the funnel must route `tend` BEFORE the sealed-pier voucher gate. It's the
    pier-less path `Swarm_reach_vouched` already uses (Swarm.g ~2276): put `tend` beside it.
- **Why not `%Reach,for:call`** (RemoteHeist §2½)? Reach is the right home for intents that should survive a reload
   and be re-asked (fetch this track). A tend call is a command with a sequence number, answered once. Reach's
    (to, of, for) idempotency would collapse repeated calls. Rule: **one frame kind, one answer, no retry**. The face
     retries by pressing again (a new seq).

#### 5.3 The CLI: `scripts/tend.mjs`
- `node scripts/tend.mjs <verb> [k=v …] [--box=<url>] [--key=<keyfile>]`.
- Builds the envelope, signs with `signHeader`, and POSTs to `<box>/tend`.
- **The key** comes from `--key`, or `TEND_KEY` = a JSON `{pub, key}` file (the shape `mintClusterKey` returns and
   `scripts/daemon` KEYFILE uses).
- **`seq`** = `Date.now()`, so it's monotone without state.
- Prints the answer JSON and exits 0, or the `why` and exits 1.
- **`--box`** defaults to `http://172.17.0.1:9099`.

### 6. Rungs (each is one Sonnet task; each ends with its proof)

**T0 — the registry, no behaviour change.**
- In `scripts/daemon/main.ts`, add `const Tend_verbs: Record<string, Verb>` where
   `Verb = { need: 'open'|'read'|'write', run: (ctx, args) => Promise<any> }`.
   `ctx = { who: string, via: 'http'|'wire'|'operator', H }`.
- Move each route's body into a verb: `status`, `census`, `profile{ms}`, `tune{idle_ms}`, `invite{base,feature}`,
   `restock`, `stop`, `dump{depth}` (= /c).
- Add one `Tend_dispatch(ctx, verb, args) → { ok, answer?, why? }`: unknown verb → `why:'no_verb'`; `need` vs `ctx` →
   §4 (the operator principal gets everything); run inside try/catch → `why:'threw: <msg>'`.
- The old routes become shims.
- **Proof:** every old endpoint returns byte-identical JSON before and after (script it: fetch each, diff). The daemon
   boots and serves (`/status` up_s climbs).

**T1 — the ledger + door binding.**
- Each `write` call that passes `may` lands one row on the box identity:
   `%Call,tend:<verb>,by:<who16>,via:<door>,seq:<seq>,ok:1|why:<word>`.
   Keep the last 50 (drop the oldest). Wall-clock time goes on `.c.at`, never sc (wall clock in sc reds fixtures,
    [[wall-clock-in-sc-reds-every-fixture]]).
- A read verb `calls` answers the rows.
- The operator door checks the remote address (§5.1). The `HOST` default changes.
- **Proof:** `/tend/restock` from this container (bridge) works. The same from a non-bridge address → 403. `calls` lists it.

**T2 — the signed call.**
- `Tend_verify` (§3) and `Tend_may` (§4) as daemon-side TypeScript. They read particles through `H`:
   `H.Swarm_live_self()`, `Swarm_peering`, the `%Grant` rows.
- `POST /tend`. `scripts/tend.mjs`.
- **Proof, a script `scripts/tend_selftest.mjs`:**
   (a) a call signed by the box's own KEYFILE → ok;
   (b) the same envelope again → `replayed`;
   (c) `to` changed → `not_for_me`;
   (d) a byte of args changed → `bad_signature`;
   (e) a fresh random key → `no_grant`;
   (f) `ts` minus 2 min → `stale`.
   All six, by word.

**T3 — the wire door.**
- `tend` + `tend_done` kinds in the Swarm hear funnel (§5.2), on the pier-less path.
- A `Tend_call(boxPrepub, verb, args)` verb on the BROWSER side (a ghost method in a new `Ghost/S/Tend.g` or in Swarm.g's
   tail), returning a Promise that resolves on the matching `tend_done` (by seq), with a 15 s deadline → `why:'no_answer'`.
- **Proof:**
   - From a live tab: `runner_ask --player=<pub> poke Tend_call <box> status` (or the console)
      → the answer arrives.
   - A Book `TendWire` on pure matter: two identities, one box. Forge three envelopes (good / bad sig / replay); drive
      `Tend_heard` directly, as SwarmBody drives reach. Swear one sentence per outcome. Gate it like the other Swarm Books.

**T4 — the grant.**
- **Mint:** `Tend_grant(boxIdent, tenderPub, scope)` mints + lands the `%Grant:Tend`. **Revoke:** `Tend_revoke` mints + lands the `%NotGrant:Tend`.
- **Two write verbs on the box itself:** `tender_add{pub,scope}` and `tender_remove{pub}`. They need `write`, so the
   owner can grant from the CLI before any UI exists.
- **The invite road:** an invite whose Feature is `Tend` (`Swarm_mint_invite(w, ident, { Tend: 1 })`). On the seal, the box
   mints `Grant:Tend` for the redeemer. Find where a sealed Music invite lands `Grant:Music` in `Swarm_accept`/`Swarm_seal`
    and add the Tend branch beside it.
- **Proof:** extend `tend_selftest`:
   (g) `tender_add` a fresh key with scope read → its `status` ok, its `restock` → `scope_read_only`;
   (h) `tender_remove` → its next call → `revoked`.

**T5 — the face.**
- In `src/lib/O/ui/DoorFace.svelte`, on the daemon's row when this tab's identity may tend it: a small `⚙` that opens a
   Cell. The Cell calls `Tend_call(box,'status')` every 5 s **only while mounted** and shows cpu / mem / ticks / woke /
    listeners.
- **Buttons:** invite (shows the link), restock, quieter (`tune idle_ms=2000`), and `calls` (the ledger).
- **Proof:** owner walk.

### 7. Laws
- **One dispatcher.** Doors parse and verify, nothing else. No verb reads `req`, `res` or a frame.
- **The call is the trust.** Never admit a tend call on a voucher, a socket, a token over a public port, or a friendship.
- **Answer first, then act**, for `stop`: send the answer, then exit after 200 ms.
- **Answers are plain JSON scalars/objects**, small (≤ 64 KB). `dump` keeps its depth cap.
- **Refusals are words**, from the fixed lists in §3/§4. A face shows the word.
- **Nothing here is Book-visible** except the T3 Book on pure matter. The daemon is not a gate
   (`Daemon_todo.md` §6).

### 8. Touch points
- `scripts/daemon/main.ts`: `http.createServer` handler (`url.pathname === …` chain), `token_ok`, `safe_json`, `say`, `stats()`.
- `src/lib/cluster_trust.ts`: `signHeader`, `verifyHeader`, `prepubOf`, `mintClusterKey`.
- `src/lib/O/Funk/Grant.ts`: `mint_grant`, `verify_grant`, `grant_to_C`, `grant_of_C`, `mint_revoke`, `verify_revoke`.
- `Ghost/S/Swarm.g`:
   - the hear funnel kind list (~2140);
   - `Swarm_reach_vouched` (~2276) for the pier-less path;
   - `Swarm_voucher_ok` (~2163), for what NOT to depend on;
   - `Swarm_mint_invite` and where invites land grants;
   - `Swarm_deliver`;
   - `Swarm_live_self`;
   - `Swarm_crew_grant` (~107).
- `scripts/ghost_compile.ts:58,100`: precedent for a CLI signing with `signHeader` + `loadRoleKey`.

### 9. Open for the owner
- **The name:** Tend / Operate / Steward ("steward" already means something in `Pool.g`).
- **Scope:** is `read` vs `write` enough, or per-verb grants (`scope: 'restock,invite'`)?
- **Friends:** does a Music friend get `read` (status) without a Tend grant?
- **Signed answers:** should the box sign its answers (a `tend_done` signed by the box key) so a face can trust them
   over the relay? Recommended for T3. It's cheap.
