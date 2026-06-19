# Agency → Hovercraft — de-entangle Housing's machine from the legacy Agency ghost

## Destination (corrected)

The think-loop has **already migrated into Housing**. `Housing.beliefs()` *is* the
 old `agency_think()` — the header at `Housing.svelte.ts:883` says so verbatim
  ("beliefs: was channel_beliefs() / agency_think()"). The whole Agency elvis-
   routing layer is likewise native in Housing now:

- `agency_think` → `beliefs()` (organise → attend → reqdo_sweep)
- `i_elvis` / `Modus_i_elvis` (the `setTimeout(…,11)` routers) → Housing's
   `i_elvisto` (`:535`) + `i_elvis`/`_i_elvis` (`:569`); out-of-time re-entry is
    now `reqyoncile` + the `%req` supervised pool, and ref-targeted delivery is
     `_deliver_targeted` (`:1056`, handler `e_<elvis>`).
- `handle_elvising_to_Modus` / `elvised_A_w` / `Aw_route` / `o_elvis` /
   `elvised_completely` → `_expand_Aw` (`:720`) + `_e_targets_T` (`:737`) +
    `attend` (`:985`) + `do_fn_for` (`:1093`). The `o_elvis` *concept* survives
     as a `w%o_elvis:<type>` flag read in `do_fn_for` (`:1131`), not a method.
- `Aw_think` → `_Aw_think` (`:1159`)
- `procure_ways` → inlined in `attend` (`:1018`, seeds a default w + re-drives)

So **i_elvis is not how we do things anymore** — Housing's `i_elvisto` + `e_<name>`
 handlers + Aw-path targeting replaced it. None of the above gets copied.

**The actual task** is the entanglement flagged at `Housing.svelte.ts:1202-1206`:

> `self_timekeeping, agency_officing, Aw_satisfied, i_unemits_o_Aw` are NOT defined
>  here — provided by Agency ghost via eatfunc/Object.assign. … `// < could move to
>   Hovercraft`

Housing's live machine still *calls into* a handful of methods that only exist
 because the **legacy Agency ghost** is eaten onto the Modus. That makes Housing
  depend on a ghost full of `requesty_serial` + domain ways. The job: **lift those
   few methods into Hovercraft** (the negotiator that sits between Stuff and
    Housing), trimmed of the parked/relocated limbs, so Housing depends on
     Hovercraft (central), not on legacy Agency. Legacy `Agency.svelte`,
      `requesty_serial`, and Pirat\* stay exactly as they are.

## The three buckets

### A — already native in Housing → GONE (do not copy)
`agency_think`, `i_elvis`, `Modus_i_elvis`, `handle_elvising_to_Modus`,
 `elvised_A_w`, `Aw_route`, `o_elvis`, `elvised_completely`, `Aw_think`,
  `procure_ways`, `say_Aw`, plus the cruft `elvospec` and `needs_your_attention`
   (the hand-rolled deferred-job array — `H.todo`/`post_do`/`answer_calls`
    superseded it).

### B — Housing's machine still depends on them → MOVE into Hovercraft
The live callers are in Housing/Modus, so these must keep resolving on the Modus —
 move the definition from the Agency ghost into Hovercraft (same eatfunc target),
  trimmed:

| method | live caller(s) | move note |
|---|---|---|
| `self_timekeeping` | `attend` `:1010/:1039` | as-is — stamps `%self,round/est/age` |
| `agency_officing` | `attend` `:1047` | drop only the `i_unemits_o_Aw` call (→ Peeroleum); keep `i_Story_o_req_ttlilt`, the `i_journeys_o_aims` call, the `%satisfied`→`Aw_satisfied` loop, and the `KEEP_WHOLE_w` replace. `%aim`/`%satisfied` callees live in the relics region (see Landed) |
| `Aw_satisfied` | via `agency_officing` | kept whole, incl. the `%aim` carry loop; only the wake modernised — `i_elvis(w,'noop',{A:nu})` → `i_elvisto(nu,'think',…)`. Lives under relics/`%satisfied` |
| `w_forgets_problems` | `_Aw_think` `:1171`; Hovercraft `w_noproblemo` `:440` already wraps it | fold the body into Hovercraft (it's three `w.r({k:1},{})` clears); `w_noproblemo` then calls a sibling, not a ghost method |
| `reset_interval` | `Modus.the_main` `:121`, Housing `answer_calls` `:829` (optional `?.`) | the ambient `%mo,interval` heartbeat |
| `w_ambiently_sleeping` | `Directory.svelte:135` (live, non-meander) | skip-N-rounds throttle util |
| `whittle_N` | Records, Radios, Cytoscaping, Story, **`H.whittle_N` in Peeroleum.go** | front-of-`TheN` GC; expected on House, so Hovercraft is the right home |
| `prandle` | Records, Radios, Gardening, Machinery (+ legacy meander) | **went to the House class in Housing**, not Hovercraft — its `prng` field + comment already lived there (`:383`/`:384`). Per-House stream (`this.prng`), so each House is its own determinism context. |

### C — does NOT come (rebuilt / parked / domain — stays in legacy Agency)
- `i_unemits_o_Aw` — **rebuilt in Peeroleum**, not moved. How it worked (for the
   rebuild): if `w.sc.unemits` is a `{type: handler}` map and `this.PF` exists, it
    registered `PF.unemits[type] = async (data,{P,Pier}) => …` which found *every*
     `A/w` declaring that `type` in its own `unemits` and served `data` to each
      (warn if none served). It is the inversion of `PF.emit()` addressing —
       instead of an emit aimed at a named `%w`, each message *type* belongs to
        whichever `%w` declares it (the `type` becomes `ftp.$k` under `PF.emit`).
- `requesty_serial` — Pirat\* keeps it; new code uses off-pump `%req`.
- `ragate`, `raglance` — SharesModus test/domain ws.
- `rest`, `unrest`, `meander` — music-share domain ways.
- `Areset` — domain-ish actor reset; has a live Radios caller, so it stays a
   legacy Agency method for Radios. **Not moved.**

## Landed (2026-06-19)

Copied to the **top of Hovercraft's eatfunc**:

- `//#region Agency machine` (the live helpers): `self_timekeeping`,
   `reset_interval`, `w_forgets_problems`, `w_ambiently_sleeping`, `whittle_N`,
    `agency_officing` (wires in the relics below; only `i_unemits_o_Aw` is
     dropped → Peeroleum).
- `//#region relics` (kept but idle on the central House, where `%aim`/`%satisfied`
   particles are rare): nested `//#region %aims` (`i_journeys_o_aims`, `name_A`,
    `name_A_thing`) and `//#region %satisfied` (`Aw_satisfied` — `%aim` carry
     intact, wake modernised to `i_elvisto(nu,'think',…)` from the old
      `i_elvis(w,'noop',{A:nu})` — and `out_of_instructions`).

`prandle` went to the House class in `Housing.svelte.ts` (not Hovercraft). Only
 `i_unemits_o_Aw` was genuinely left out, for the Peeroleum rebuild.

**Agency is now de-included from `Ghost.svelte`** — the import and `<Agency {M}/>`
 mount are gone. This House is the island going forward, where Modus became House:
  it runs `beliefs()` (Housing), and the hovering helpers it calls come from
   Hovercraft + the House class (`prandle`), not the Agency ghost. Verified by
    grep that no central-House code (O/ + gen/, incl. Housing) calls any uncopied
     Agency method — `i_unemits_o_Aw`, `requesty_serial`, `agency_think`, `meander`,
      `rest`/`unrest`, `ragate`/`raglance`, `Areset`, `say_Aw`, `elvised_A_w`,
       `Aw_route`, `procure_ways`, `Modus_i_elvis`, `needs_your_attention` (all
        remaining hits are comments). So the old `eatfunc` last-wins / mount-order
         reliance is moot — nothing on this House defines these but Hovercraft.

Legacy `Agency.svelte` is untouched and still mounts on the **p2p Modus**
 (`Modus.svelte`), which drives via `Modus.the_main → agency_think` and keeps
  Agency's full versions (ways, journeys, unemits, `requesty_serial`). Pirat\*
   untouched. Typechecks clean over every edited file.

## Open / next (the detonators)

- **Not runtime-verified — only static.** The de-inclusion was checked by grep +
   svelte-check; `this.<method>` dispatch is dynamic, so the real confirmation is a
    **Story run on the central House** (boot the island, watch for a thrown
     "no method / undefined is not a function" from `attend`/`do_fn_for` reaching
      for an absent Agency method). Do this before trusting it. If something *does*
       break, the fix is to copy that one method into Hovercraft too — the buckets
        above say which are GONE-native vs need-copying.
- **Relics are unexercised here.** `i_journeys_o_aims` / `Aw_satisfied` only run
   when `%aim` / `%satisfied` particles exist, which is rare-to-none on the central
    House — so they've never actually fired on this island. `i_journeys_o_aims`
     also fires `i_elvis(w,'putjourney',{Aw:'Directory'})` on a path change; there
      is no `A:Directory` on the central House, so that would warn (only on a real
       journey change, which needs `%aim` first). Watch this if `%aim` ever lands here.
- **`self_timekeeping` behaviour shifted slightly.** Changed `C.oa(...)[0]` →
   `C.o(...)[0]` (CLAUDE.md's oa-isn't-for-retrieval rule). Behaviour-equivalent
    when the `est` particle exists (it's stamped the line above) — but it means
     `%age` now reliably populates where the legacy `oa[0]` form may have yielded
      `undefined`. Harmless as far as known; noted in case a snap diff surprises.
- **`name_A_thing` is dead weight** — copied into relics for completeness but has
   no caller (only `name_A` is used, by `i_journeys_o_aims`). Drop if you want the
    relic lean.
- **Larger Everything_todo items are untouched** — the Story `req:Step`/`req:Drive`
   recast, Lang/Waft/Wire, etc. remain the "what's still moving" picture; this work
    was just the Hovercraft req-migration tail / Agency de-inclusion.
