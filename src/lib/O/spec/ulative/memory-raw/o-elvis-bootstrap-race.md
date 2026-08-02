---
name: o-elvis-bootstrap-race
description: "the ~20%-on-fresh-load editor-stuck-loading-Waft bug = a lost Wormhole rw_op read dispatch, with no retry path"
metadata: 
  node_type: memory
  type: project
  originSessionId: 170fd7b7-8c92-4774-8b48-5e54f25deedb
---

The "~20% of fresh page loads the editor sticks at ⏳ loading Waft:Credence…" bug.

Symptom: a `req:LiesStore_read` sits with `%req_sent` set but never `%finished`; its
`ttlilt,waiting:LiesStore_read` goes `timed_out`. Only a PAGE RELOAD escapes (resetStory
doesn't). Fresh-load race, ~20%.

Cause (class, not pinned to one mechanism): `i_elvis_req` fires the Wormhole `rw_op` read
elvis EXACTLY ONCE — `%req_sent` then suppresses re-fire forever. That single fire can be
LOST: a fresh-load race where the read reaches Mundo's `w:Wormhole` worker before it first
stamps `{o_elvis:rw_op}` (then routes to a non-existent `e_rw_op` and is dropped — see
`Housing.do_fn_for`), Mundo not yet ticking, a torn-down sub-House, etc. There is NO retry:
`req:Store` only pumps inside `LiesRealised`, which a stuck read never reaches (LiesPersist
returns `!settled` and bails early).

Tried first & REVERTED: a `do_fn_for` `!has_e_handler` fallback (route a marker-less typed
elvis to the w-method instead of dropping). Sound in theory but DID NOT fix it — so the
marker race isn't the (whole) cause; the loss is elsewhere too. Reverted to keep the core
dispatch untouched.

Actual fix (`LiesStore.svelte` `LiesStore_read`): self-heal. LiesPersist re-calls
`LiesStore_read` every tick while loading, so it's the one live retry point. When an
unfinished read's ttlilt has `timed_out`, the fire is gone → `delete req.sc.req_sent` +
drop the dead ttlilt, so the existing `i_elvis_req` + `i_req_ttlilt` lines re-dispatch and
re-arm. The fresh ttlilt also keeps Story's poll non-quiescent, so the boot step keeps
ticking us until the read lands (instead of finishing half-loaded). Retries ~every 1.6s;
a genuinely-absent file still finishes via not_found, so it's bounded in practice.

Related: [[ttlilt-not-a-keepalive]] (ttlilt won't retry on its own), [[snap-inclusion-vs-pump]].
:9091-UNVERIFIED — needs a few reloads to confirm the hang is gone.
