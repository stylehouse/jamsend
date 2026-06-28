# Waft — the medium (pointer doc)

> **2026-06-28 — gutted.** Waft turned out to be *generic-C number one*: a named,
> persistable container, an **indifferent medium in which you expect Whats, Docs and
> Points**. That philosophy now lives where it belongs — atop `src/lib/O/ui/Waft.svelte`.
> The old body of this spec (the Interest family, the cursor, presence, the Point-class
> decoration layer) has either **graduated into live code** or **moved into the
> attention-layer trio** below. What's left here is the durable grammar, the
> face-is-a-Funkcion rule, and a map of where each old section went — so the ~25 inbound
> `Waft_spec §…` references still land somewhere true.

## The attention layer — three docs, one medium

A Waft just sits there holding children. Three things *do* something with it:

- **`Interest.md`** — the Lang↔Lies **attention channel**: how Lang comes to attend a
  Waft, the `%Interest,<kind>` family (Trail · Aside · Ting · GhostList), the cursor it
  carries, which lens is on stage. *The Interest is the channel; the Waft is its subject.*
- **`Keeping_spec.md`** — **persistence** of that attention: focus, cursor and open-set
  resume from `Waft:Keep`; the kind-table that elects a Waft's stance + its startup Funkcion.
- **`Lang_handover.md`** — the **editor surface**: edit → compile → fold → `.go`, the
  document tree the Interest's cursor points into.

## The Waft medium — the What tree

A Waft is `Waft → (What | Doc)*`. `What` is the universal container; `Point` is a leaf:

```
Waft  → (What | Doc)*
What  → (What | Doc | Point)*
Doc   → (What | Point)*
Point → (nothing — leaf)
```

`What` is polymorph by depth: a section heading at the top of a Waft; a **time-slice**
(the old `Flock`) nested in a Doc, where successive sibling `What`s are successive
moments; a subsection nested in another `What`. Snap shape:

```
Waft:Ghost/LakeNets,Ghost/LakeNets
  What:foundations
    What:story
      Doc:Ghost/test/Story/Peeroleum.g
      Point,method:LakeNetherland
  What:transport
    What:first look
      Doc:Ghost/test/Story/Lake/LakeAntecedents.g
      Point,method:transport
```

## The face is a Funkcion, the stance is a property

A Waft's **face** is its main Funkcion — a `%Funkcion,main` child resolved through
`O/Funk/kinds.ts` (`FUNK_KINDS`) and mounted generically by `FunkHost` (DocTing rides
`Funkcion:Ting`, DocGhostList rides `Funkcion:dirlist`). A Funkcion is an applet embedded
in the document: declaration in the snap (`Waft/Funkcion:<kind>`), behaviour off-snap on
`funk.c.run` — a **monitor** if its kind has `run` (pumped each tick), an **action** if
not (struck on demand). The Waft's **stances** — `takes | aside | minimised | equip` —
are plain `%`-properties a lens reads, not types and not render branches. `Waft.svelte`
knows only Waft/What/Doc/Point and "mount the main Funkcion"; everything else rides as a
Funkcion or a property.

## Where the old sections went — for the `Waft_spec §…` back-references

| old §                                          | now lives |
| ---------------------------------------------- | --- |
| §Interests, §The duality, §The family          | `Interest.md` — the `%Interest` family table |
| §How an Interest comes to be                   | `Interest.md` §2 (the `waft_roster` subscription) |
| §Waft vs Interest — the border                 | `Interest.md` — the Waft↔Interest ownership split |
| §The cursor the wire carries                   | `Interest.md` §3 Phase A (per-Interest cursor) + `LiesCurse.svelte` |
| §Funkcions — the embedded applets              | `O/Funk/kinds.ts` + `FunkHost.svelte`; summarised above |
| §Presence — which lens is on stage             | `Interest.md` §3 Item 1 + `InterestStrip.svelte` |
| §What — the universal container                | the grammar above |
| §Graduation ledger (Point class · squish · transport) | `Langui.svelte` (decoration), `LiesCurse.svelte` (carry-over), `Keeping_spec.md` D1 (playback dropped) |
