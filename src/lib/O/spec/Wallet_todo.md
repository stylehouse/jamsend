# Wallet_todo — what this tab is, on the wire, at a glance

*Started 2026-11-18 from the owner's ask ("we need a nice understandable wallet icon thing … to say what its address is"),
 after a `/Desk?G=Land` tab answered nobody: its cluster identity read "none".  DESIGN, not built — the owner: "think it out
  really well".  Companions: `Crew_todo.md` §0.00 (the plain crew model + its glossary — no "soul"/"body"),
   `Identity_persist_todo.md` (where an identity comes from), `Tab_reach_todo.md` (how a tab is reached), `Cluster_spec.md`.*

## 0. What to get on with next

**STATE 2026-11-18 (owner): §2 RULED + BUILT; the wallet itself PARKED — "maybe not at all though, do we really need that?" … "we might
 need it".**  §2 landed in `Otro.svelte` (a Ground page with `Role:hacker` | `Role:player` and no `?I=` gets `id_role` hacker | sound +
  `assume_identity`, exactly as its Big*land twin): a headless `/Desk?G=Land` came up "🪪 Identity hacker swift-koi — page default",
   hello'd at `<pub>_9115` and stood in the census.  §3–§4 wait until the wallet is needed — most of its reason ("none" silently
    breaking reach) went with §2.

**Rule first, then build the wallet.**  Proposed order: (1) every page has an identity (§2 — one rule in Auto, owner's call);
 (2) the wallet as ROWS on the top House (§3); (3) its face in every page's header (§4).  Each step is useful alone.

**The owner, the same evening: "this whole Identity thing… it's sprawley" · "we eventually need to make the socket an understandable
 appliance… and Identity etc".**  So the wallet is the FRONT PANEL of that appliance, and the honest first job is to make the sprawl
  visible in one place before shrinking it.  Today a tab's "who am I on the wire" is spread over: the active `%Identity` (A:Clustation),
   its storage name (`?I=` | role | adopt), each world that stands a socket (w:Lies, w:Swarm's station, LandPage's w:Wire — ClusterAddressing
    §4.5: two sockets, one prepub), what each socket's hello bound (`<pub>` or `<pub>_NNNN`), its door (`become` role), the flock proof,
     the editor seat, `/Crew`, the grants.  Nine places, no one row.  The appliance shape — ONE socket per tab, owning hello, flock,
      seat and doors, that worlds RENT rather than each standing their own — is the destination; the wallet's rows (§3) are the
       inventory that redesign starts from.  (Verified the same evening: with `&I=new` the Land tab became 5c738deb and its `:ask` passed.)

## 1. Why a tab said "none"

An identity comes from one of three places, first wins: `?I=<prepub>` on the URL; a legacy adopt; or the page's DEFAULT —
 `Clustation_ensure_default` resumes (or mints once) the identity stored under the page's ROLE name (`sound`, `word`, …).
  Only pages booted through `boot_qualand` opt into a default (`H.c.id_role`): `/BigSoundland` is always the `sound` identity,
   `/BigWordland` always `word`.  **A Ground-booted `/Desk?G=…` page never opts in** — so `/Desk?G=Land` with no `?I=` is no one:
    it cannot say hello under an address, nobody can reach it (`--player=`), and its own `:ask` is refused at the relay.

And today nothing on the page SAYS any of this.  The 🪪 Id button opens the IdHatch — a setup panel (mint, import, cluster trust),
 not a readout — and "none" there is the whole explanation a person gets.

## 2. Every page is someone (DECIDE)

Proposal: a Ground's `Role:` names its default identity exactly as `boot_qualand` does — `Role:hacker` → `word` (so the two hacker
 pages, BigWordland and `/Desk?G=Land`, are the same someone), `Role:player` → `sound`, a runner its own.  One rule, in Auto, where
  `auto_ground` reads the Ground.  `?I=` still wins.
- **Two tabs, one identity** is then normal (two hacker pages, as now two music tabs).  The relay already handles it: the second
   tab's hello binds `<pub>_NNNN` (the "seat dodge"), the first keeps the bare name.  Which tab is "the" one — the mutex UI — is the
    later question the owner parked; the wallet only has to SHOW it (§3 `%Door`).
- Not decided here: whether a Desk page should prefer the profile's last-used identity over its role's.

## 3. The wallet is rows, not a widget

The bet: state is legible living matter.  So what the wallet shows is particles on the top House — `A:Wallet / w:Wallet` —
 kept by one small think from what is already true elsewhere, and read by the face, `minisnap 'mundo>A:Wallet'`, and a Book alike.
  (A Book could then swear "this page answers at its own name" — which no snap can say today.)

```
A:Wallet / w:Wallet
  %Who:<nick>,pub:<prepub>,by:url|role:<name>|adopt     ← the active Identity, and where it came from (or %Who:none,why:…)
  %Door:<relay addr>,role:runner|player|hacker|editor,live   ← one per socket this tab holds (Lies channel, LandPage's wire,
                                                                Swarm's station — ClusterAddressing §4.5: two sockets, one prepub)
    %Twin                                                  ← it stands at <pub>_NNNN: another tab holds the bare name
  %May:ask                                                 ← proved a cluster flock key at hello → may runner_ask, may seat
  %May:seat,held                                           ← holds the editor seat (only an editor/hacker with docks asks)
  %Crew:<role>,captain?                                    ← in /Crew, as which mate; the Captain's key or a crewmate's own
  %Friends,n                                               ← how many live grants (a count — the names live in Swarm)
```

- **Only public things.**  The prepub, never a key; a count of friends, not who.  Nothing here is a secret, so a Book may snap it.
- **Wall clock stays on `.c`** (hello time, last heard) — CLAUDE.md "wall clock in .sc reds every fixture".
- **Kept, not computed in the face** — one think re-reads the sources (active Identity, each world's `hello_ok_at`/`flock_ok`, the
   relay addr hello_ok named, `/Crew`, grants) and moves rows only when a fact moved (LandPage `Land_say` is the shape).
- Owed for it: the flock proof leaves no positive mark today (`flock_ok` only deletes `flock_tries`) — add `w.c.flock_ok_at`.

## 4. The face

- **In every page's header** (Otro, beside the actions): `👛 brass-tern · e747cbed` plus one dot per door — filled when live,
   hollow when not — and 🐑 when the flock is proven.  `👛 no one` in a warning colour when `%Who:none`, its title saying why
    (§1) and what fixes it (`?I=`, or the page's default once §2 lands).  Small: it is a readout, not a panel.
- **Click** opens a card, not the IdHatch: the address in full with a copy button (what `--player=` and a friend dial), each door
   with its role and address, `%May` lines in words ("can ask runners", "holds the editor seat"), crew and friends counts, and at
    the bottom the existing doors out: "identities & cluster trust…" → the IdHatch.
- **Words** (Crew_todo §0.00's): identity, address, the Captain's key, a crewmate's own key.  Never "soul" or "body".
- The 🪪 Id action stays (it is the setup door); the wallet replaces it as the READOUT, so the button can later fold into the card.

## 5. Not doing now

- The mutex between two tabs of one identity (owner: later).  The wallet shows `%Twin`; it decides nothing.
- Switching identity from the wallet — the IdHatch already does it; the card links there.
- The crew key redesign (Crew_todo §0.00's "BAD DESIGN") — the wallet only reads `/Crew`.
- Reaching unarmed music pages (Tab_reach_todo: arming is the owner's consent, the only switch) — the wallet can SAY "not
   reachable: not armed", it must not arm.
