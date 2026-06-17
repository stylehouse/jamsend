# Interest — surprise_read popover + the channel-as-big-attention idea (handover)

Picking up from the graduated `%Interest` channel.  Item 5 (surprise_read resume/diff)
got an **inline** first leg; this note is the **next** leg — lift it into a *popover that
pops out of the Interest channel*, and seed the larger "Interest = big-attention
channel" idea behind it.  Fresh session recommended: the work is exploratory (UI infra
study) and the prior session's context was mostly the inline build + a test-diff triage.

## Done — the foundation (in the working tree, keep it)

The resume/diff *mechanism* is real and wired; the popover reuses all of it.

- **Backend stash** — `req_LiesStore_writeCarefully` (LiesStore.svelte) stamps
  `good/%surprise_read` on an external-edit conflict, now carrying:
    - `sr.sc.text`      — mine (on-snap; can't be re-derived, survives reload)
    - `sr.sc.dige`      — mine's dige
    - `sr.sc.disk_dige` — theirs' dige
    - `sr.c.disk_text`  — theirs, off-snap (re-fetched on reload)
- **Resume legs** (Lies.svelte, next to `e_Lies_source_write`):
    - `e_Lies_surprise_keep_mine`   — `LiesStore_write(sr.sc.text)`, drop the stash.
      req_Store Phase 1 re-stamps `/known`, so the next auto-save sees no divergence.
    - `e_Lies_surprise_take_theirs` — drop stash, `delete good.c.content`,
      `Lies_provide_dock` to re-land disk text in the open editor.
  Fired by `H.i_elvisto('Lies/Lies', 'Lies_surprise_keep_mine'|'Lies_surprise_take_theirs', {path})`.
- **Inline UI** — `ui/DocRow.svelte` shows a conflict row (⚠ + keep mine / take theirs
  + a "diff" toggle) when `good/%surprise_read` is present.  `ui/DocDiff.svelte` is the
  diff widget: a plain DMP line diff (theirs→mine, context-elided) — deliberately NOT
  `H.compute_diff` (that one is snap-specialised / peel-normalised; a Doc is opaque source).

The inline row is the fallback / proof.  The popover below supersedes it as the primary surface.

## BUILT — the popover (this session)

The popover is now in the tree:
- `ui/SurprisePopover.svelte` — scans `w:Lies/req:Store` Goods for the first
  `good/%surprise_read` (reaches w:Lies via `H.ave`'s `%examining`.c.w, the same seam
  Liesui uses, so it stays live without a parent re-render).  Renders a Storui-flavour
  `Vexpandy popup={true}` (position:fixed at top of viewport, z-index 500 — FaceSucker
  wasn't needed): ⚠ + path, keep mine / take theirs (the existing elvis legs), and an
  **escalate** ("go to Lies ↓") that fires `Dock_open` then `scroll_to_house(H)` after a
  50ms layout settle (mirrors Storui's `go_to_diff`).  Esc dismisses (the inline DocRow
  row remains as fallback); resolving the conflict clears `good/%surprise_read`, so
  `conflict` goes null and the popover closes.  No × kill button.
- Mounted from `ui/InterestStrip.svelte` (the channel) — rendered unconditionally with
  its own gate, so it pops regardless of whether any Interest caps are showing.
- Fabrication moved out of DocRow into **Ballistics — the havoc drum-machine** (the flat
  loaded-docs list that once hosted the button is gone; the Funkcion/Ballistui/House-UI first
  cut was scrapped — Funkcions are the auto-pumped Lies behaviours, the wrong model).  A
  **limb** is authored as content: a `%havoc` particle (`{havoc:<kind>}` + optional
  `emoji`/`hint`) dropped **anywhere in a Waft tree**.  `Waft.svelte`/`waftitem` renders it
  **inline as a strike pad** (💥 + kind); a switcheroo Waft in raw mode shows the bare
  particle instead.  The particle is pure config; behaviour lives in `Lies/HAVOC_LIMBS`
  (`kind → {run(H,w)}`), and `e_Lies_strike {kind}` runs it + wakes a tick.  Add a limb =
  add a `HAVOC_LIMBS` entry — pad + dispatch are by kind.  First limb `surprise_read` →
  `Lies_fabricate_surprise_on(w, path)` on the **active doc** (`H.Awo('Lang').c.active_dock_path`;
  `examining.sc.active_path` is dead — nothing writes it).  Author `havoc:surprise_read` in a
  test Waft, tap it → conflict on the open doc → popover pops.
  - **Deferred** (user's "another whole concept"): a limb that *arms itself* — receives
    `think()` while the `What**` it sits in is engaged / not folded away (Lang openness +
    Scrollability) — instead of only firing on a manual strike.

Still open from the original plan:
- **Move InterestStrip's `×` into PeelInput** — left as a follow-up; it's a distinct UX
  refactor (the strip caps would re-render through PeelInput's CRUD irow, which already has
  a `pi-irow-del` ×).  The popover itself already has no kill button.
- **Escalate target** — `scroll_to_house(H)` lands on the whole Lang/Lies House header,
  not the Liesui sub-element; could be tightened to target the Liesui content.  And the
  inline DocRow's diff is a per-row toggle, so escalate doesn't auto-open it — landing on
  the glowing row (with its own keep/take/diff) is the seam for now.

## Original plan — the popover (what to build)

The conflict should **pop out of the Interest channel**, not just sit in the doc list.
The thinking: Interests *are channels*; a surprise_read is *this Interest's business* —
the giver Trail that owns the open Doc is the natural place for the IDE to escalate a
"something big wants your attention" moment.  (Note the seam: the Doc/`%Good` is
*acquired separately* from the Interest — Good lives under `req:Store`, the Interest is
a Lang-side roster row — but the *attention escalation* belongs to the Interest.  Future:
other subsystems integrate as Interests precisely to claim big attention in the IDE; the
surprise_read popover is the first inhabitant of that pattern.)

Shape:
- A **popover** in the Storui flavour: a `position:fixed` `Vexpandy` near the top of the
  viewport so the user can keep using the editor while it's up.  Copy the Storui mechanics:
  `Storui.svelte:556+` (the Resnapture popup — `popup_open / popup_expanded / popup_step`
  `$state`, ave `$effect` trigger, Enter-to-act), and `ui/Vexpandy.svelte`.
- **Emanates from the Interest** — anchor/route through `ui/InterestStrip.svelte` (the
  giver Trail row that owns the conflicted Doc), rather than DocRow.  This is where the
  "channel" reading lives.
- **Actions in the popover**: keep mine / take theirs (already wired), plus an
  **escalate-to-Lies hop** — mirror Storui's `go_to_diff()` (`Storui.svelte:574`): close
  the popover, `H.top_House().scroll_to_house?.(<the w:Lies UI>)`, and land on the full
  diff over in Lies.  Many situations will want this "bigger expression of the situation",
  in-popup *or* over in Lies — so build the escalate + scroll-into-view as a reusable seam.
- **Dismissal**: no `×` on the Interest.  Move InterestStrip's current `×` (the `dismiss`
  fn, `ui/InterestStrip.svelte:67`) deeper into **PeelInput**.  The popover closes by
  resolving the conflict or by Esc, not a kill button.

### Fabricate a surprise_read (do this first — it unblocks demoing)

Real conflicts are rare, so add a dev affordance that injects a synthetic one: stamp
`good/%surprise_read` with `sc.text` (mine), `sc.disk_dige`, and `c.disk_text` (theirs)
on a loaded Doc's `%Good`, then `good.bump_version()`.  A tiny `e_Lies_fabricate_surprise`
elvis handler (path + optional fake disk text) is enough; wire a debug button to it.  With
that, the whole popover/keep/take/escalate loop is exercisable without a second editor.

### UI infra flavours to study (the user's palette)

- **Storui popup** — `Storui.svelte:556-595` — the canonical position:fixed Vexpandy +
  `go_to_diff` + `scroll_to_house`.  Closest prior art; start here.
- **NaviScroll** — `ui/NaviScroll.svelte` — the scroll-target measurer go_to_diff defers to.
- **Scrollability** — `p2p/ui/Scrollability.svelte` — scroll-into-view flavour.
- **FaceSucker** — `p2p/ui/FaceSucker.svelte` — the overlay/hoist primitive: wraps
  content in an `altitude`→`z-index*1000` container, optional `fullscreen` (`position:fixed`
  full viewport).  This is the layer to *float the popover above the IDE* — "twisting up
  space."  Used as `<FaceSucker altitude={N} {fullscreen}>…</FaceSucker>` (see
  `MTrusting.svelte:181`, `mostly/Cytoscape.svelte:504`, `p2p/Intro.svelte:103`).  Likely
  pairing: FaceSucker (hoist) + Vexpandy (expand/collapse) for the popover body.
- **NaviScroll is probably retiring** (user) — confirm before leaning on it; prefer the
  `scroll_to_house` API on top_House as the durable seam.

## The umbrella — Interest/Point metromap UI (larger TODO, not now)

The popover is a first step toward the real picture the user wants: a tiny **animated SVG
metromap** of the two layers of Interest/Point working —
  1. **Interestily sprouts the activeWhat** via an *obscured network* (the giver Trail
     reaching the active What), then
  2. the activeWhat **sprouts its Points**.
Nodes carry **"elsewheres" that fold away** like a real folded metromap showing only a few
nodes; the creased **horizon edges stay faintly readable in the background, behind the
words**.  No `×` (dismissal lives in PeelInput).  This extends item 1 of the graduation
handover (the InterestStrip switcher) from a button strip toward a spatial channel map.
Park it; the surprise_read popover proves the "Interest pops out big attention" mechanic
that the metromap later generalises.

## Housekeeping carried over

- **InterestLive Step:1 test diff is benign** — a one-time Waft-block reorder:
  `Lies_order_wafts` → `w.place({Waft:1}, sorted)` re-`i()`s the Wafts, appending the block
  to the end of `w`'s children (below `Funkcions`/`wants`/`o_elvis`).  Stable afterwards
  (place's identity no-op guard).  The rest is rolling telemetry (`want=…`, `time,compile`,
  `TimeSpool` samples).  **User re-records exp on the host** — don't chase it as a bug.
  (If churn ever annoys: give order_wafts an in-place reorder that keeps the block's anchor
  instead of sinking it — optional.)
- Don't stage/commit — human owns the diff (CLAUDE.md).
