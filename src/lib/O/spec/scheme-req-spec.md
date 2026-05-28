# scheme:req — extra req spaces for i_Story_o_req_ttlilt

## Problem

`i_Story_o_req_ttlilt` walks `w`'s direct reqcons tree.  Reqs on `docC`
particles (`w/docs/doc:path/**`) are invisible to it because `w:Lang` has no
reqcons lineage through `docs`.

There is also a second problem: `i_req_ttlilt` climbs `req.c.up` looking for a
particle with `sc.w` set, in order to stamp `w.c.has_req_ttlilt`.  The
`w/%docs/%doc` path doesn't carry `.c.up` wirings (those particles aren't req
hosts), so the climb dead-ends before reaching `w:Lang`.  `has_req_ttlilt` never
gets set, and Story is never told to hold the snap open.

Both problems need fixing.

## Solution

### 1 — `w/{scheme:'req'}` + lematch chain (walker side)

Lang declares once:

```
w:Lang
  scheme:req,declared:1
    lematch:1,sc_has:{docs:1}
      lematch:1,sc_has:{doc:1}    ← terminal: visit() each docC
```

`i_Story_o_req_ttlilt` extends its walk: after `visit(w)`, if `w` has a
`{scheme:'req'}` particle, it follows the lematch chain up to 5 levels deep,
calling the existing `visit()` on every terminal particle reached.

### 2 — `i_scheme_req(w, req, secs, sc)` helper (arm side)

Because the c.up climb is broken for docC-hosted reqs, arming a ttlilt on such
a req needs to set `w.c.has_req_ttlilt` explicitly.  A thin helper wraps
`i_req_ttlilt` and does that stamp directly:

```js
// Hovercraft — alongside i_req_ttlilt
i_scheme_req(w: TheC, req: TheC, secs: number, sc: TheUniversal = {}): TheC {
    const t = this.i_req_ttlilt(req, secs, sc)
    // c.up chain doesn't reach w through non-req particles (docs/doc);
    // stamp has_req_ttlilt on the known w directly.
    w.c.has_req_ttlilt = 1
    return t
},
```

Callers that already have `w` in scope (like `Lang_graft_points`, which has
`w:Lang`) call `H.i_scheme_req(w, req, secs, sc)` instead of
`H.i_req_ttlilt(req, secs, sc)`.  For reqs whose c.up chain reaches `w`
normally, `i_req_ttlilt` is still correct; `i_scheme_req` is only needed when
the chain is broken.

## Particle declarations

### On `w:Lang` (once, in the `w.c.Lang_setup` block)

```js
// Declare req spaces so i_Story_o_req_ttlilt finds reqs on docC particles.
// docs → doc is the only path; update lematches if the layout changes.
const scheme = w.oai({ scheme: 'req' })
if (!scheme.sc.declared) {
    scheme.sc.declared = 1
    const lm_docs = scheme.i({ lematch: 1 })
    lm_docs.sc.sc_has = { docs: 1 }
    const lm_doc = lm_docs.i({ lematch: 1 })
    lm_doc.sc.sc_has = { doc: 1 }
}
```

### On `docC` (at creation time, wherever `docC` is first `oai`'d)

```js
// Declare graft req channel so the scheme:req walk's visit() finds it.
docC.oai({ reqcons: 1 }).oai({ reqcon: 'req:graft' })
```

Full snap:
```
w:Lang
  scheme:req,declared:1
    lematch:1,sc_has:{docs:1}
      lematch:1,sc_has:{doc:1}
  docs:1
    doc:Ghost/test/Hello.g,active:1
      req:graft,path:Ghost/test/Hello.g
        ttlilt:1,until_ts:T,waiting_for_compile:1
```

## Hovercraft patch: `i_Story_o_req_ttlilt`

Add after `visit(w)`, inside the per-w loop, before the `gathered` sort:

```js
// scheme:req extension — visit extra req-hosting subtrees declared on w.
// lematch chain up to 5 levels: sc_has narrows the search at each level;
// terminals (no child lematches) get the full visit().
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
                visit(found)
            }
        }
    }
    for (const root_lm of req_scheme.o({ lematch: 1 }) as TheC[]) {
        follow(w, root_lm, 0)
    }
}
```

## Hovercraft patch: `i_scheme_req`

New method alongside `i_req_ttlilt`:

```js
// i_scheme_req — arm a ttlilt on a req whose c.up chain doesn't reach w
// (e.g. reqs on docC particles under w/%docs/%doc).  Stamps has_req_ttlilt
// on the known w directly instead of relying on the broken climb.
i_scheme_req(w: TheC, req: TheC, secs: number, sc: TheUniversal = {}): TheC {
    const t = this.i_req_ttlilt(req, secs, sc)
    w.c.has_req_ttlilt = 1
    return t
},
```

## Lang_graft_points patch

```js
// After cache-key early-return, before Pmirrors replace:
const pending = job?.o({ Pending: 1 })[0]
if (pending && points.length) {
    // Compile hasn't settled — hold Story open and retry next tick.
    const graft_req = docC.oai({ req: 'graft', path: active_path })
    H.i_scheme_req(w, graft_req, 0.5, { waiting_for_compile: 1 })
    return
}
// Compile ready — drop stale graft req so its ttlilt evaporates.
await docC.r({ req: 'graft', path: active_path }, {})
```

## Wiring order

1. Hovercraft: `i_scheme_req` method.
2. Hovercraft: scheme extension in `i_Story_o_req_ttlilt`.
3. Lang: `scheme:req` + lematches on `w` in setup block (~L111).
4. Lang: `reqcons` for `req:graft` on `docC` at creation (~L162).
5. LangGraft: `Lang_graft_points` patch using `i_scheme_req`.

Steps 1–4 are independent.  Step 5 depends on all of them.
