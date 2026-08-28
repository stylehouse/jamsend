# Focus_todo.md — who commands the screen: the toplevel focus authority

The owner, 2026-08-28, after a day of whack-a-mole: *"we really need the toplevel, who's stealing
 the user's focus state formulated carefully"* — and earlier the same day, the sentence this whole
  doc answers: *"everything needs to be massaged into and out of the vision of the user.  where is
   your datastructure of what we're showing the user?  what cell is the dominant one?"*

This is the formulation.  It is a `_todo` (working doc), deliberately NOT self-promoted to spec —
 the owner reads + preens before that.  Its companion is `Atheory_todo.md` (the Housing/loader
  rebuild); this doc is the ATTENTION half of the same toplevel, `Atheory` is the LOADING half.

---

## 0. The thesis

There are TWO focus authorities in this app and only one of them is modelled.

- **Inside the glass**, `Sounditron_commission` already answers "what cell is the dominant one":
   `w.c.focused` / `focused_keep` → the belly ladder → one `big`/`stretched` belly, the rest buds.
    That model is good.  It is the answer to the owner's "what cell is the dominant one" AT THE
     GLASS SCALE.
- **Above the glass** — the FULLSCREEN surfaces that seize the whole viewport — there is NO model.
   Each surface decides FOR ITSELF whether to be up, reading its own signal, at its own z-index, with
    its own latch.  They do not know about each other.  So they fight, strand, and hide each other,
     and every bug below is one of those collisions.

**The claim: the toplevel needs the SAME kind of authority the glass belly has — one datastructure
 that says which fullscreen surface is dominant right now, why, and what it yields to.**  Not a pile
  of independent `{#if}`s each computing "should I be up" from a private signal.

## 1. The focus-stealers (inventory — verify against the tree; some z-indices are from memory)

Every surface that can command the whole viewport, what raises it, how it lifts, and its z:

| surface | file | raised by | lifts on | z / altitude |
|---|---|---|---|---|
| **Butler** (arrival) | `ui/Butler.svelte` | page load, until arrival | `Supervisor_arrived==='arrived'`, or `guts`, or machine_tab; latches `H.c.butler_done` | FaceSucker alt 55 |
| **BootGate** (FSA/audio tap) | `ui/BootGate.svelte` | `disk_gated‖ac_wanted` & `!butler_up` | the gate satisfied | FaceSucker alt 77 |
| **the boot tap INSIDE Butler** | `ui/Butler.svelte` | same gate, when butler_up | tap harvests the gesture | (inside Butler) |
| **the gaveup remedy** ("▶ start the music") | `ui/Butler.svelte` | `arrived==='gaveup'` & remedy | the remedy taken | (inside Butler) |
| **the Link/Adopt consent cell** | `Sounditron_commission` → LinkFace | `Swarm_link_active` (ferry pending/secret) | ceremony ends | a GLASS cell (needs arrival first!) |
| **the ▦ guts switch** | `V/BigSoundland.svelte` | always rendered (opacity .2) | toggles `guts` pref | 999999 |
| **the proposed boot splash** (tree.webp) | (unbuilt — this session) | app start | arrival / peek | above Butler |

The tell that these are uncoordinated: **BootGate is altitude 77, Butler is 55** — Butler is
 *deliberately* under BootGate and then *suppresses itself* (`butler_up`) so two gates don't stack.
  That suppression is a hand-wired peace treaty between exactly two of the seven surfaces.  There is
   no treaty for the other twenty-one pairs.

## 2. The collisions this session — each is a missing treaty, not a local bug

Every fix this session was patching one edge of the ungoverned graph:

1. **Shuffle dead-end** — `Sounditron_focus` re-commissioned the wrong world and a bare cell
    replaced the glass.  *Missing:* a commission may never dispatch a glass with no way home
     (patched: the way-back ensure).  A focus authority would never have let a home-less frame win.
2. **Link cell pointer-shield** — the Link mold's rectangle shielded Door/Radio, and lingered
    through its fold.  *Missing:* the glass_kinds pointer-events contract as an INVARIANT the
     commissioner enforces, not each face remembers.
3. **"start the music" toggled to stop** — the remedy button called a toggle; the autopress had
    already started the radio.  *Missing:* the remedy is a one-way GOAL ("be playing"), and two
     things (autopress, remedy) drove the same state with no owner.
4. **Ferry consent never surfaced** — `ferry_park` set `ferry_pending` but nothing re-commissioned,
    so the Link cell never rose on a cold receiver.  *Missing:* an arriving ceremony is a
     FOCUS EVENT that must command the screen; instead it set a flag nobody was watching.
5. **Stuck-outside on a sealed-but-offline friend** (the live one, 495233) — a sealed Music friend
    who is offline makes the tab "not solo", so the peerless autopress won't play its own music;
     nothing plays; `arrive.playing` gives up; the Butler squats; **the Adopt consent that should
      own the screen is stranded behind a FAILED arrival.**  *Missing (two):* (a) "solo" must mean
       *no friend reachable NOW*, not *no friend sealed ever* — an offline friend must fall back to
        your own music; (b) a pending Adopt must OUTRANK a gaveup arrival for the screen.

Five bugs, one shape: **a surface that should be dominant was blocked by, or blocked, another
 surface, because nobody ranks them.**

## 3. The formulation — a single toplevel focus authority

Model the fullscreen layer the way the glass models the belly: **one ranked authority deciding the
 ONE dominant surface, its reason, and what it yields to.**

**3.1 The datastructure.**  A `%Screen` (or a plain `top.c.screen`) the toplevel owns, holding:
  - `dominant` — the single surface that has the viewport now (`boot-tap | arrival | ceremony |
     splash | glass | gaveup`).
  - `reason` — the machine fact that raised it (the honest sentence, from the Supervisor where
     possible — never a face's private guess).
  - `yields_to` — the higher-priority surfaces that can pre-empt it, so a transition is legible.
  - it is `.c` (never snapped), read by every fullscreen face instead of each computing its own
     `up`.  The faces become *renderers of a decision*, exactly as glass cells render `focused`.

**3.2 The priority ladder** (highest wins the screen; each rung names the machine fact):
  1. **boot-tap** — `disk_gated ‖ ac_wanted`.  A permission the human must grant; nothing proceeds
      without it, so it outranks everything.  (Today: BootGate/Butler, hand-coordinated.)
  2. **ceremony** — `Swarm_link_active` (an Adopt/ferry arriving or in flight).  A consent that
      cannot wait and must not hide behind a boot log or a failed arrival.  **This is the rung the
       stuck tab needed and did not have.**
  3. **arrival** — booting, `Supervisor_arrived==='none'`.  The splash/Butler carry the wait.
  4. **gaveup** — `arrived==='gaveup'`.  Arrival can't complete; say so + offer the remedy.  Ranks
      BELOW ceremony (bug 5) — a stuck arrival must never squat over an Adopt.
  5. **glass** — `arrived==='arrived'` ‖ `guts`.  The app.  The default winner once nothing above
      is true.

**3.3 The rules that fall out** (each retires a hand-wired treaty):
  - Exactly ONE dominant surface; the ladder is total, so no two can both believe they're up (kills
     the BootGate-vs-Butler altitude hack — they become rungs 1 and 3 of one ladder).
  - A surface renders ONLY when it is `dominant`; it owns no `up` of its own (kills the private
     latches that stranded people — `butler_done`, `splash_done`, the four dead arrival clocks).
  - The authority is HUMDINGER-gated and READ-mostly, so runner/Book tabs (no humdinger) get an
     empty screen authority and every fixture stays byte-identical.
  - `reason` comes from the Supervisor roster, so the toplevel "names no subsystem" (Butler's own
     law) — a watch registered tomorrow can raise a surface tomorrow with no toplevel edit.

**3.4 What this is NOT.**  Not a new renderer, not more chrome.  It is the missing MIDDLE of the
 existing three-scale attention model: page-load → **[this: which fullscreen surface]** → glass
  belly (`focused`) → cell guts (`need`/pose).  The glass scale and the guts scale are modelled; the
   fullscreen scale is the hole, and it is where every stranding lives.

## 4. Ties to Atheory (the loader half)

`Atheory_todo.md` owns "how code loads onto the base Housing".  The two meet at the toplevel: the
 focus authority is a thing the rebuilt toplevel should OWN and stand up early (before the glass,
  since boot-tap and ceremony can precede arrival).  If Atheory rebuilds the toplevel, it should
   bake in §3's authority rather than re-scatter the seven surfaces.  Sequencing: this doc's model
    can land as a small `%Screen` coordinator on the CURRENT toplevel first (retiring the treaties
     one rung at a time), and Atheory can absorb it — designing the coordinator does not block on the
      rebuild, and proving it on today's toplevel de-risks the rebuild.

## 5. First moves (when the owner greenlights)

- **Cheap correctness now, model later:** the stuck-tab fix (bug 5) is two edits independent of the
   authority — (a) "solo" = no friend *reachable now* (an offline sealed friend falls back to own
    music: the autopress/arrival peerless rung should read live reachability, not sealed-count); (b)
     a pending `Swarm_link_active` should raise the consent even from a gaveup arrival.  Land these
      as the FIRST two rungs of §3.2 (ceremony > gaveup) to prove the ladder pays off immediately.
- Inventory-harden §1: sweep for every `FaceSucker` / fullscreen `position:fixed inset:0` and every
   `H.c.*_up`/`*_done` latch; the table above is memory-grounded and wants a real audit.
- Draft the `top.c.screen` shape + a `Screen_decide()` (pure, testable, Supervisor-fed) and make
   ONE surface (the Butler) read it instead of its own `up`, as the pilot.  If that holds, migrate
    the rest one rung at a time.
