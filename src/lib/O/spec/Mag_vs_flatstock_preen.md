# Mag vs flat-stock — where audio holdings live (preen doc)

Two design docs rule contradictorily on where a `%Record` holding lives under a shelf.
 DOC A (`Radio_spec.md §2.4`) says the settled shelf is FLAT and Mags only refer in.
  DOC B (`Mag_todo.md §1`) says stock IS `%Mag/%Cloud/%Record` and explicitly supersedes §2.4.
   This is decision-ready: one wins, the loser's still-true clause is preserved as a carve-out.

## HUMAN

**Recommendation (do this):** Promote DOC B (`Mag_todo.md §1`) to spec — it is what the LIVE code
 already does (§2). §2.4's flat ruling is superseded in fact, not just on paper.
**But keep §2.4's GC-invariant as an explicit carve-out** in the promoted spec: identity-per-shelf +
 "Mags/Grasps ARE the GC root set" still holds, and friend/quarantine mirrors + the un-built
  `%Original` master / `%Blob` export are still-flat BY DESIGN (§3) — don't let promotion erase that.
**Resolve one open sub-question first** (§4): `Ra_recs`/`Ra_rec_find` are fixed at 3 depths and
 SILENTLY DROP anything deeper — so the spec must state whether a Mag may nest (Cloud-in-Cloud /
  Mag-in-Mag) or is pinned at one Cloud layer. Everything else is settled.

---

## 1. The exact contradictory claims

**DOC A — flat (the OLD ruling):**
- `Radio_spec.md:253` — "**why the settled shelf is FLAT** — a `%Blob|Original` never 'sits inside'
   something else, because bytes live in exactly ONE place (the settled shelf) and every MEANING …
    is a `Mag|Grasp` *referring* in by id, never containing."
- `Radio_spec.md:134` (§2.3) — "a **`%Card`** is a *listing*, never a holding … The card is a
   **referring particle** wearing its own mainkey; the shared `id` is the free join to the holding."

**DOC B — branched (the NEW ruling that SUPERSEDES A):**
- `Mag_todo.md:5` (§0) — "This doc SUPERSEDES the old §2.4 'stock stays flat, Mags only refer'
   ruling — see §1."
- `Mag_todo.md:143` (§1) — "A holding does not float flat under a shelf; it lives under a **Mag**."
- `Mag_todo.md:165` (§1) — "**Landed 2026-07-19 (§0.1):** the real shape is
   `stock/ > %Mag:shuffle > %Cloud,page:N > %Record`."

## 2. What the CODE does TODAY — DOC B is LIVE

Grep of `Ghost/M/Ra.g` (built 2026-07-19, per `Mag_todo.md:39` candidate 1):
- `Ra_rec_home` (`Ra.g:627`) is "**THE ONE DOOR every owned mint walks**" — a new holding "lands in
   the open shuffle page, **never flat**" (`Ra.g:623`, `Ra_mag_page(Ra_mag_shuffle(shelf))`).
- `Ra_mag_shuffle` (`Ra.g:608`) find-or-creates `shelf.oai({Mag:'shuffle'})`; `Ra_mag_page`
   (`Ra.g:614`) pages it 1-based, 6/page (`Ra_page_size`, `Ra.g:605`).
- `Ra_recs` (`Ra.g:649`) / `Ra_rec_find` (`Ra.g:661`) are the shape-agnostic census EVERY reader
   rides — a plain `shelf.o({Record:1})` "starves on a paged shelf" (`Ra.g:648`).
**Verdict: the paged Mag model is the live model.** Flat is legacy; only the mirrors/quarantine below
 still lay flat, by design.

## 3. What still argues for "flat"

§2.4's flat reasoning protected a real invariant, and B keeps it: bytes live in exactly ONE place, so
 "the GC root set is exactly the Mags|Grasps, and a holding nothing refers to is reapable"
  (`Radio_spec.md:256`). B does NOT break this — identity-per-shelf still holds (`Mag_todo.md:159`:
   "the thing exists ONCE as its `%Record`; every other mention is a referring `%Card`").
Still-flat carve-outs B itself names (not oversights):
- **Friend mirrors stay flat** — `Mag_todo.md:168`: "Friend mirrors stay FLAT until the wire cut
   carries Mag structure"; the **quarantine mirror** stays flat in code (`Ra.g:624` — "not yet a
    collection, so its minter never calls" the door).
- **The heist landing mints** (census import, cp-landing card, Jam keeper) "still lay flat
   deliberately … Wants its own ruling before those mints page" (`Mag_todo.md:51`, §0 OPEN RULING) —
    origin stock was resolved (`§0b origin-lib-pages`, DONE, `Mag_todo.md:106`).
- **`%Original` master + `%Blob` export** are not yet on the paged shape at all — "re-home into this
   shelf|shop still owed" (`Radio_spec.md:220`), so that master layer is conceptually flat for now.

## 4. Open sub-question — does the Mag nest deeper?

`Ra_recs` (`Ra.g:649`) and `Ra_rec_find` (`Ra.g:661`) "hard-code exactly three shapes — flat
 `shelf.o({Record:1})`, `Mag.o({Record:1})`, and `Mag > Cloud.o({Record:1})` — they do **not**
  recurse" (`Mag_todo.md:133`, §0b `ra-recs-recurse-question`). That matches today's one-Cloud model,
   "**but if a Mag is meant to nest arbitrarily deep (Cloud-in-Cloud, Mag-in-Mag), both silently drop
    the deeper rows**" (`Mag_todo.md:136`). The human flagged this 2026-07-21. It must be answered in
     the promoted spec: pin at one Cloud layer, or make the two a recursive walk.

## 5. Recommendation (3 lines)

1. Promote `Mag_todo.md §1` → `Mag_spec.md`; retire `Radio_spec.md §2.4`'s flat clause as historical.
2. Carry §2.4's GC-root/identity-per-shelf invariant forward verbatim as a "still true" clause, and
    list the deliberate flat carve-outs (mirrors, quarantine, heist landing mints, un-built master/Blob).
3. Before promoting, RULE the recurse question (§4) — one Cloud depth vs recursive `Ra_recs` — since it
    is the one place the live code silently drops data if the model grows.
