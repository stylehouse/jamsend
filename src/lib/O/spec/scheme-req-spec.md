# scheme:req — extra req spaces for i_Story_o_req_ttlilt

## Problem

`i_Story_o_req_ttlilt` walks `w`'s direct reqcons tree.  Reqs on `docC` particles
(`w/docs/doc:path/**`) are invisible to it because `w:Lang` has no reqcons for `docs`.

`i_req_ttlilt` already climbs `req.c.up → docC → docs → w:Lang` correctly and sets
`w.c.has_req_ttlilt`.  The walker finds the right `w`; it just can't reach the reqs.

## Solution: `w/{scheme:'req'}` + lematch chain

Lang declares once (in the `w.c.Lang_setup` block):

```
w:Lang
  scheme:req
    lematch:1, sc_has:{docs:1}
      lematch:1, sc_has:{doc:1}    ← terminal: call visit() on each docC
```

`i_Story_o_req_ttlilt` gets a scheme extension after its main `visit(w)`: if
`w.o({scheme:'req'})[0]` exists, walk its root lematches recursively (up to 5
levels), calling the existing `visit()` on every terminal particle reached.

## Particle declaration (Lang, in `w.c.Lang_setup` block)

```js
// Declare req spaces for i_Story_o_req_ttlilt to find reqs on docC particles.
// docs → doc is the only path; update lematches if the layout ever changes.
const scheme = w.oai({ scheme: 'req' })
if (!scheme.sc.declared) {
    scheme.sc.declared = 1
    const lm_docs = scheme.i({ lematch: 1 })
    lm_docs.sc.sc_has = { docs: 1 }
    const lm_doc = lm_docs.i({ lematch: 1 })
    lm_doc.sc.sc_has = { doc: 1 }
}
```

Snap:
```
w:Lang
  scheme:req,declared:1
    lematch:1,sc_has:{docs:1}
      lematch:1,sc_has:{doc:1}
  docs:1
    doc:Ghost/test/Hello.g,active:1
      reqcons:1
        reqcon:req:graft
      req:graft,path:Ghost/test/Hello.g
        ttlilt:1,until_ts:T,waiting_for_compile:1
```

## Hovercraft patch: `i_Story_o_req_ttlilt`

Add after `visit(w)`, inside the per-w loop:

```js
// scheme:req extension — visit extra req-hosting subtrees declared on w.
// lematch chain up to 5 levels deep: each lematch.sc.sc_has narrows the
// search, terminal (no child lematches) particles get the full visit().
const req_scheme = w.o({ scheme: 'req' })[0] as TheC | undefined
if (req_scheme) {
    const follow = (host: TheC, lm: TheC, depth: number) => {
        if (depth > 5) return
        const sc_has = lm.sc.sc_has as Record<string, any> | undefined
        if (!sc_has) return
        const sub_lms = lm.o({ lematch: 1 }) as TheC[]
        for (const found of host.o(sc_has) as TheC[]) {
            if (sub_lms.length) {
                for (const sub of sub_lms) follow(found, sub, depth + 1)
            } else {
                visit(found)   // terminal: treat as req host
            }
        }
    }
    for (const root_lm of req_scheme.o({ lematch: 1 }) as TheC[]) {
        follow(w, root_lm, 0)
    }
}
```

Position: immediately after `visit(w)` and before the `gathered` sort and replace.
The inner `visit()` closure is already in scope; no signature changes needed.

## Lang_graft_points patch

Graft req lives on `docC` (not `w:Lang`).  `i_req_ttlilt` climbs
`req → docC → docs → w` and sets `w.c.has_req_ttlilt` correctly.

```js
// After cache-key early-return, before Pmirrors replace:
const pending = job?.o({ Pending: 1 })[0]
if (pending && points.length) {
    const graft_req = docC.oai({ req: 'graft', path: active_path })
    H.i_req_ttlilt(graft_req, 0.5, { waiting_for_compile: 1 })
    return
}
// Compile ready — drop stale graft req so its ttlilt evaporates.
const stale_graft = docC.o({ req: 'graft', path: active_path })[0] as TheC | undefined
if (stale_graft) await docC.r({ req: 'graft', path: active_path }, {})
```

The `docC.reqcons` for `req:graft` needs to be declared for `visit()` to find it.
Add to the `docC` creation site in `Lang_doc_from_event` (or wherever docC is
first `oai`'d):

```js
// Declare graft req channel so scheme:req walk finds it.
docC.oai({ reqcons: 1 }).oai({ reqcon: 'req:graft' })
```

## Wiring order

1. Hovercraft: add scheme extension to `i_Story_o_req_ttlilt` (~L573).
2. Lang: declare `scheme:req` on `w` in setup block (~L111).
3. Lang: declare `reqcons` for `req:graft` at docC creation (~L162).
4. LangGraft: `Lang_graft_points` ttlilt patch.

All four changes are independent — apply in any order, test after all four land.
