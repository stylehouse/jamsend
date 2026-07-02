# DocWaftMap — sketch of the Doc-relevance Lens

*GhostList reshapes a flat **file** list into a stem tree. This is its sibling: reshape the flat
**Waft**** into relevance — which Docs live in which Wafts, and which Docs are shared across them.
A Lens (see `Lies_handover` §5), so the mechanism is thin: one component, one `FUNK_KINDS` line.
Everything below is the component's own work.*

## What it shows

Two organisations of one walk, toggled:

1. **By Waft** — a group per Waft, listing its Docs. A Doc that also lives in other Wafts wears a
   badge (the count, or the other Wafts). The shared ones are the interesting ones.
2. **Shared (the Venn)** — the overlap only: every Doc in ≥2 Wafts, bucketed by the *set* of Wafts
   it belongs to. Each distinct Waft-set is one Venn region. (A literal N-circle diagram doesn't
   survive past three Wafts; a region-list does — one row per shared set.) A region *is* a
   promotable in-group: click it to bring its shared Docs up as a switchable list.

## The set it walks — three tiers, none a fresh guess

I narrowed this to "just the Interest roster" earlier — wrong. There are three canonical tiers,
each already maintained; DocWaftMap *layers* them rather than choosing one:

- **Known — the durable roster.** The Keep's ledger: `Keep/{WaftTimes,of_Waft:<path>}`, one child
  per Waft ever noted (`Lies_keep_note`), each carrying `discovered_at`/`accessed_at` and a per-Waft
  cursor. This is the identity list — *every* document Waft, **loaded or not** (the "other bunch of
  Wafts that aren't loaded" — they live here). Keyed by source path (`Ghost/Music/Ality`,
  `Ghost/Net/Easy`). This is what stops the Lens being bare-arsed about finding a Waft: the names
  come from the Keep, not a live walk.
- **Loaded — the walkable subset.** `w.o({Waft:1})` minus `!equip` (GhostList/Keep/Cluster/Funk/
  Credence fixtures) minus `!takes` (the Ting scratch). Only these have a live `%What → %Doc` tree
  and a `%Map` of headings — because only these have been loaded and `Waft_dip`-ed.
- **Attention — the highlight.** The foregroundable Interests (`Trail + Aside`, InterestStrip's
  roster) — which *loaded* Wafts are hot right now. Orders and emphasises; never restricts.

So: **rows** come from Known, **headings/Docs/Venn** from Loaded, **hotness** from Attention.

**List all, drill selectively.** The row list is *every* Waft — fixtures and the Ting sink included,
so nothing is hidden — but only `!equip && !takes` Wafts get their Docs drilled out for the Venn: a
fixture has no document Docs to share, and the Ting is a scratch sink. That list-vs-drill split is
why there's no single clean "document Wafts" getter to lean on.

**The stances aren't one set (the bearings).** `equip` and `takes` are *orthogonal* `%`-stances
(`ui/Waft.svelte:12`), gating different things:

- `equip` = a backstage **fixture** (Keep/Cluster/GhostList): folds from the snap, out of the
  cursor's way — **but persisted** (the Keep writes `wormhole/Keep`).
- `takes` = a session **sink** (the Ting): receives globulated taps, **never persisted** —
  `Lies_waft_save` short-circuits on `sc.takes`, so there is no `wormhole/Ting`.

Ting isn't `equip` because it isn't a fixture; its non-persistence rides `takes`, and that's
sufficient. So "the documents" is *neither stance whole* — which is exactly why we're **not**
enshrining a `Lies_document_wafts(w)` getter yet: one getter can't carry list-vs-drill. (The
candidate, if we change our minds: `w.o({Waft:1}).filter(wf => !wf.sc.equip && !wf.sc.takes)`.)

## It's a TOC and a launcher, not only a Venn

A row per Known Waft, showing its **headings** (the `%Map` regions — the same TOC the minimap draws)
once loaded. A cold (unloaded) row shows its name + recency from the Keep; clicking it
**loads → dips → cursors in**, exploding its contents (the existing want/foreground path already
loads a Waft on focus). So DocWaftMap doubles as the navigator into the whole corpus, and the
Venn/Doc-overlap is one view *within* it — over the Loaded tier, where the Doc trees exist.

Headings for an *unloaded* Waft aren't in hand today: `%Map` is Lang-compile output on loaded docs,
and the Keep ledger holds identity + cursor + times, not a TOC. Caching a headings snapshot in the
Keep so cold rows show their outline *before* load is the natural extension this vision wants — a
decision, not a given.

## The data (buildable today)

Row list = the Keep ledger (`Keep.o({WaftTimes:1})`, mapped by `of_Waft`), unioned with the Loaded
Wafts (a Waft can be open before it's noted). For each *loaded* Waft, collect its Doc paths
(`Waft → %What → %Doc:<path>`, plus What-child Docs); build `docPath → Set<Waft>`, then derive:

- per-Waft Doc lists → organisation 1;
- the `docPath`s with `|Wafts| ≥ 2`, grouped by their Waft-set → organisation 2.

**Cheap by construction — not a walk of the big tree.** Row identity is the flat Keep ledger, read
once. Per loaded Waft, Docs are a 2-level shallow read (`Waft → %What → %Doc`); you never descend
into Points. `Waft_dip` (LiesFunk) already ran the heavy per-Waft structural index on load / in-place
edit — stamping each particle's `c.Dip` (stable, rename-proof address) and each Point's `c.Doc`
(governing Doc). DocWaftMap is the *reduce* over what's already indexed: a `$derived` off the
top-Waft-list + Keep-ledger version, recomputed on a bump. Off-snap, no re-parse — as
`DocGhostList`'s `groups` are today.

## Interaction

- **Click a Doc** → focus its Waft and land on that Doc (the existing want/foreground path). For a
  shared Doc, *which* Waft's copy is a decision below.
- **Hover/click a Waft the Venn names** → **scroll the page to that Waft** — bring its Waft-column
  node into view (`scrollIntoView` on the node keyed by Waft path). The map doubles as a scrollbar
  into the corpus: every Waft it mentions is a jump target, not just a label.
- **Click a Venn region** → promote its Docs as the current switchable in-group.

## Plug-in (the thin part)

A new `DocWaftMap.svelte`, plus one line in `FUNK_KINDS` (`waftmap: { component: DocWaftMap }`).
Where it mounts is the one real architecture call — see decisions.

## Brief it well (read before building)

The truest sibling is **InterestStrip, not DocGhostList** — DocGhostList indexes *files*; this
re-organises the *attention roster*.

- `src/lib/O/ui/InterestStrip.svelte` — `rows`/`hot`/`cold`, `tail_name`, `foreground()`. This Lens
  is a re-organisation of exactly that list.
- `src/lib/O/Lang.svelte:80-90` (Interest shape: `sc.waft`/`sc.src`/`c.LE`/`c.What`/`in_Doc`) and
  `:1200-1282` (roster reconcile: open Wafts → Interests, `interest_reconcile`).
- `src/lib/O/LangHold.svelte:455-536` — `foregroundable = Trail + Aside`, LE binding.
- `src/lib/O/Lies.svelte:158-166, 1032-1067` — the `!equip` filter + boomerang arbiter (the
  definition of "not %equip / background never steals").
- `src/lib/O/LiesKeep.svelte:60-160` — the `WaftTimes` ledger (`Lies_keep_note`, `of_Waft`,
  `discovered_at`/`accessed_at`): the **Known** roster, and the durable home if cold-headings get cached.
- `src/lib/O/LiesFunk.svelte:69-142` — `Waft_dip`: what's already indexed per Waft (`c.Dip`, `c.Doc`).
- The `%Map`/minimap readers (`Lang_map_span`, DocMinimap) — the heading source for **Loaded** rows.
- `src/lib/O/Lies.svelte:760-775` — the load path (`Waft_dip` on place); the want/foreground focus
  path is the "click a cold row → load → cursor in" launcher.
- `src/lib/O/spec/Interest.md`; `Lies_handover.md` §1/§5; `Backbone_plan.md` — the one-move.
- `DocGhostList.svelte` — reuse its `$derived`-off-snap *pattern* only, not its file-index data.

## Built — a Funkcion in the Keep (concentric capsules)

**The home is the Keep Waft's main Funkcion**, not a floating bar. Two earlier mounts were tried and
 dropped: a **Brink Lens tenant** (never showed on the plain app — the hoist rode `Lies_heartbeat`,
  which only runs for `?E=`/`?B=` Runs, and the Brink defaults collapsed) and a **fixed `ui/Plank.svelte`
   bar** (it *showed* but was dead to clicks: the Brink's `.lens-dock` is `position:fixed; inset-x:0;
    bottom:0; z-index:40000` — spanning the full viewport bottom above the Plank's 9490). Both deleted.

Now: **`waftmap: { component: DocWaftMap }`** in `FUNK_KINDS`, embedded as `%Funkcion:waftmap,main`
 under `Waft:Keep` (`Lies.svelte` persist phase, right after the GhostList block). `ui/Waft.svelte`'s
  `main_funk` resolves it → **DocWaftMap is the Keep Waft's body**. *Open the Keep to see the map.*

- **Editor-only, off the runner, for free.** `Lies_keep_boot` is editor-gated (`Lies_role==='editor'`),
   so `Waft:Keep` exists *only* in an editor Run. The embed's whole gate is `if (keep)` — a runner has
    no Keep, a bare Lies has no Keep, both skip. No role check, no heartbeat. (And the Keep's ledger —
     the **Known** tier — is editor-populated anyway, so an editor home is the *correct* one.)
- **Concentric capsulation.** A Waft is a `.cap` capsule; expand it → its Docs are `.cap-doc` capsules
   nested inside (`.cap-in`, an indented spine well); expand a Doc → its **guts** (the `%Map` region|def
    headings, read lazily from `Doc→%Compile→%Map` only when open) flow inside. Boxes within boxes.
- **No inner scroll.** The old `.pk-body { max-height; overflow-y:auto }` (the "scroll-on-hover") is
   gone — as a Waft body it flows and the Lies panel scrolls.

Clicks work (it's an ordinary inline Waft body, not fighting the z-40000 dock). Data reads unchanged:
 **Known** rows (`Keep/WaftTimes`) / **Loaded** Docs (`!equip && !takes` via `Lies_walk_docs`, now
  keeping the Doc `c` ref for the guts) / **Attention** hotness (Languinio Interests).

**Jump-scroll** (the star move, the ⇱ button beside each loaded Waft): `scrollIntoView` its live cursor
 (`.ls-item-what-active`, the Spotlight) → again → the Waft's top → again → cursor, toggling. A *pure
  viewport move*. The Doc **→** button is the destructive land (`Lang_foreground` + `Lies_want`, in the
   Waft you clicked under). The Waft/Doc header itself now expands the capsule (cold Waft → loads).

Type-clean; :9091-unverified (open `Waft:Keep` in an editor Run — the map is its body).

### Next (owner's vision, not yet built)
- **The stem-join** — render the shared Wafts `Waft,Waft(ghosts…)Waft,Waft` StemHive-style (one Waft
  left, two right) instead of the flat region-capsule list. StemHive clusters by name-token; a Waft-set
  join needs its cluster model fed pre-computed — a real design pass.
- **Jump-to-remembered-cursor** for a *non-foreground* Waft (needs per-particle DOM anchors; today only
  the foregrounded Waft has a live cursor marker, so others jump to top first).
- Cold-row `%Map` TOC caching so an unloaded Waft shows its outline before load — and mind the clash:
  `Map` is already `%Compile/%Map`'s mainkey, so a headings cache must use a *distinct* mainkey
   (`Toc`/`Outline`) on the `WaftTimes` record.
- (Parked) a floating presentation — if the map ever wants to hover always-visible again, the same
  `waftmap` kind can grow a `comp_<Lens>` hoisted face beside the inline `component`; the Keep stays home.
