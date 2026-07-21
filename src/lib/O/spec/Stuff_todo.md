# Stuffing — the k:v regrouping algebra, re-said in stho and Book-proven

The pane-content distiller (what a fold|gang pane SAYS) lifted out of the crush, re-expressed
 clean in stho, and proven in isolation on a live runner — the first step of "rebuild the Stuffing
  pipeline in stho" (the human, 2026-07-21). A working `_todo`, not a spec.

## HUMAN — one ruling owed (recommendation first)

**The `row:vein` leg is NEW and PROVISIONAL — it needs your yes/no.** Recommendation: **keep it, coexisting**
 with the per-key rows (that is what shipped and is green). The three sub-calls, in case you want to change them:
- **Add it at all?** — YES (shipped). `Vtuff_keyrows` reads key-by-key and structurally cannot see a value
   that crosses keys; the sizing algebra wants that "one value · many keys = a global vein" signal. It is the
    one leg your algebra named (`k1:v k2:v → (k1|k2):v`, the dual of spread) that the old engine never had.
- **Supersede or coexist?** — currently COEXISTS: the vein Example emits `fact,k:genre,v:dub` AND
   `fact,k:mood,v:dub` AND `vein,v:dub{genre,mood}` — the same fact said three ways. Cleaner might be for the
    vein to SUPERSEDE the per-key facts it subsumes. Left as a knob; say which.
- **Weight?** — `wgt:2` (louder than fact|spread's `wgt:1`), on the "said once and loud" intuition. A guess.

Everything else below is landed and green; only the vein leg's *presentation policy* is open.

## 0. What to get on with next

- **Rule on the vein leg** (above), then tighten `Stuff_veinrows` to match.
- **Re-home the distiller into the new glass.** `Stuff_distil` lives in `Ghost/Story/Voronation.g` (beside its
   proof) for now — its permanent home is `Vyto_fold` (`Vyto.g:294`, currently a `return` stub; the moult's
    "fold ITSELF stays in Voro.g until the first tenant proves the seam" — this is that tenant). The re-home
     adds the DETACHED-mint variant (`new TheC`, Books-invisible) the real glass contract wants; the Book uses
      the attached-mint (`into`) so the tree snaps as proof.
- **The top-down algorithm is still owed** (`Vyto_sizing_todo.md §0`). This Book proves ONE station of it
   (Stuffing → the `%Vtuffing` tree that carries `wgt`/`n` prosody). The full pipeline —
    Scannable(Seem-pronounced) → **Stuffing regroup** → importance → global `S` → cell area → attention taper
     → cut → render — is not yet written down as one law.
- **Importance-carrying**: the `%Vtuffing` format already carries `wgt` (per row) and `n` (counts) — the
   prosody the sizing algebra reads. When wiring the taper, decide whether the vein's cross-key breadth should
    lift its importance further (a vein carried by many keys is a strong global signal).

## The decision that shaped it — KEEP the `%Vtuffing` format

The regrouping algebra and its output format ALREADY EXIST: `Vtuff_keyrows` (`Ghost/V/Voro.g:1911`) builds a
 `%Vtuffing / %Vrow / %Vbit` tree (title · fact · spread · list · member · dip; specced `Voro_vtuffing.md:483`),
  and Cytui only PAINTS it. So "rebuild in stho" is a faithful **re-expression + port**, not a greenfield.
   Rather than invent a new `%Stuff` grammar, `Stuff_distil` emits the SAME `%Vtuffing` tree, because:
- it is already typed k/v end-to-end (the 2026-07-14 Stuffing-shape cut) and already carries `wgt`/`n` prosody;
- keeping it makes the existing `Vtuff_build` a **correctness oracle** (the stho re-say must reproduce it for
   the shared legs);
- it does not fork Cytui's paint vocabulary (the display avoid-zone), so the eventual `Vyto_fold` re-home is a
   drop-in.

The clarity win of "rebuild in stho" lands in the CODE (a clean, commented station) and in the format finally
 being written down here — not in renaming data. (Doc drift noticed: `Voro_vtuffing.md:493` still shows
  composed `text:'habit: vine'` strings; the CODE is typed `k/v` — the examples there are pre-typed-cut stale.)

## What landed (all green on the live runner, --runner=49dee91d61a9de64)

`Ghost/Story/Voronation.g` (appended, `//#region Stuff`):
- **`Stuff_distil(into, members, kind, skips)`** — the entry; mints the `%Vtuffing` root and calls the two passes.
- **`Stuff_keyrows`** — the key-by-key pass, a faithful re-say of `Vtuff_keyrows` (render decorations tag|c.members
   dropped — those are paint|hover, not the algebra): ONE value → a `fact` said once (a bare `1` → a COUNTED
    presence fact, only when some-not-all carry it — a universal presence says nothing); MANY → a `spread` of
     `%Vbit` chips, counted (the ×N multiplicity), ranked most-common-first, capped at 3 + an honest `+N` tail.
- **`Stuff_veinrows`** — THE NEW LEG: a value crossing ≥2 keys → `row:vein,v,wgt:2` with a `%Vbit,k,n` per key.

`Stuffing` Book (same file) — five bags, one per leg, each an `%Example` holding its members + its distilled
 `%Vtuffing` (attached → snapped → the fixture IS the proof, no glass, no pixels):
- **agree** → `fact genre:dub` (5 dub tracks said once) beside a title spread with `+2` tail.
- **spread** → `spread year` with `2007 (n=2)` ranked before `1998 (n=1)` — multiplicity proven.
- **vein** → `fact genre:dub` + `fact mood:dub` + `vein dub {genre n=2, mood n=1}` — the new leg.
- **overflow** → `fact title:Comp` + `spread label` capped at 3 + `+2` — no silent drop.
- **presence** → `fact remaster n=3` (counted, no value) while universal `Track` says nothing.
- beat 3 RE-BREATHES the vein (a 4th dub-via-genre carrier lands → `genre n=2→3`) — proves the field is live.

Recorded: `wormhole/Story/Stuffing/toc.snap` + `001–004.snap` (4 steps). Check-mode re-run reproduces every
 dige byte-for-byte (pure function). **Adversarial probe**: raising the vein threshold to `>=99` (no veins) turns
  steps 2–4 RED (`ok_pct 0.25`, only the empty step 1 survives) — the fixtures genuinely gate. Registered on the
   Credence board under `What:Voro`.

## Notes for the next author

- `%see` sentences are comma-free, apostrophe-free, em-dash for pauses (this file uses `%see`, matching its
   VoroTest/VoroScape neighbours; the newer `story_swear` regime is the alternative — see `see-assertion-layer`).
- Recording a fresh Book: `run <Book>` new-mode auto-records; `run.sc.total` in the do_fn bounds it; rm any stub
   `wormhole/Story/<Book>/` before a clean record; heal the HMR begun-wedge with `runner_ask reload`. (Full
    mechanics + the `.g` unclosed-brace trap that cost this session: memory `g-authoring-gotchas`.)

**Cross-refs:** `Voro_vtuffing.md` (the `%Vtuffing` format + the paint side), `Vyto_sizing_todo.md` (the owed
 top-down law this feeds), `Springcore_meander.md §the grammar of compression` (why Stuffing computes the
  importances the size algebra needs), `Vyto.g:294` (`Vyto_fold`, the re-home seam).
