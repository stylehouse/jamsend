// yeti etc!!!!!
theCompiledStuff(A,w) {
    i hut/toot:3
    o hut/toot$
    let la = i hut/$toot
    o hut/although:1,they,can,be,mixed
    i $la/something
    i thung/wither/etc
    i yeses/because,it:2
    i yeses/because:five,it:5
    A i %prefixy:'stuffule sivi'
    A i %prefixy:`i th/re/e = ${1 + 2}`
    A i %prefixy:stuff,wither:angles

    A o %wither$
    A o yeses$
    // row capture: wither:1 filters, vish = the row C (%prefixy,wither)
    A o wither$vish

    // . binds tight and grabs the %wither value to tuple amongst other stuff
    A o prefixy,wither.$ang
    // multi-capture destructure: ang flows in on %are, then so|module|etc each
    //  grab a value out — so auto-names so, the others name sooo|tv|etc|year.
    //   .$ takes the value (?.sc,key); a bare $ would take the row C instead.
    w i angles/are:$ang,etc:3/so:ont.$sooo,module.$tv,etc.$
    w i angles/are:$ang,etc:3/so:ont.$soow,module.$tw,etc$yeaw
    
    // you can declare let variables like this:
    $its = 'ferv'
    // should be strings 'stuff', 'levels', 'its', but then sits='ferv'
    A i %prefixy:stuff/wither:levels,its:its,sits:$its
    

    &nothinging,A,w,555
    &nothinging,A,w,{figuira:'out', all_these:3}
    if (&nothinging,A,w,{figuira:'out', all_these:3}) 3+2+4
    if &nothinging,A,w,{figuira:'out', all_these:3}
        && 6
        3 + 3
    // we should prefer no semicolon on the end of control structures
    //  just continuating expr and indent indicate:
    if &nothinging,A,w,{figuira:'out', all_these:3}
        && 6
        3+2+4
        3 + 2

    // loosely binding if block maker. right of and is a block so can contain ;
    !0 and w i wibble_andily
    // && binds tighter than and — the whole run left of the LAST and is the condition
    33 && 44 and w i compound_andily
    // chained EXPR and EXPR and STMT — each condition operand is parenthesised, so a
    //  looser || inside one keeps its grouping: (0 || 1) && (!0), not 0 || (1 && !0)
    0 || 1 and !0 and w i chained_andily

    [3]
    S o yeses/because
        let val = because.sc.it
        i figiura/datch:$val
    if 3
        i know
    if 0
        i dont/know
    elsif 1 && 0
        && 50
        i never/knew
    elsif 50 > 5
            && 3 > 2
        i helped
    i yep
    &severally,A,w,555
},
nothinging():
    return true && true
severally(A,w,thing):
    i miles,of,words
    i miles,of,wordings
    i thingure:thing,of,wordings
    i thingure:$thing,of,wording
    thing += 6
    H.laterally(A,w,thing)

laterally(A,w,thing):
    i thingure:$thing,of,word:$thing/really

moreTiles(A,w):
    // newer capture coverage the corpus hadn't exercised yet.
    //  (a trailing capture names its own let — no manual let prefix needed.)
    // value capture on a multi-leg o — tval = the %toot value, not the row C.
    //  .$:name is the value-OUT spelling (mirror of :$ value-in); .$name still reads.
    o hut/toot.$:tval
    // single leg, two value captures → tier0-multi takes the caps drill
    A o prefixy,wither.$:angle,its.$:itsval
    // a multi-leg i whose freshly-inserted leaf we keep — no capture, so the
    //  let is manual, binding the drill's return (the leaf C)
    let leaf = i deep/nest/leaf
    // ── frontier — commented; documents the path syntax still to come ──
    // @ark: a capture name advertises a column (an ark); @name reuses it,
    //   multi-row.  $ang above named a column, a sibling IOing reads it back:
    //  o angles/are:@ang/module$
    // fan-out: a mid leg matching N rows makes the captures below it N-wide
    //   (columns — basically a database); wants the taxonomy seam first:
    //  w o angles/are:$ang,etc:3/so:ont.$sooo
    // the -> flow form splits the obtain from the insert across @are:
    //  w o angles/are:$ang,etc:3
    //  -> i @are/so:ont.$sooo,module.$tv,etc.$

// the r / rm / replace family.  r and rm are IOness2 verbs compiling to async
//  TheC methods, so they emit `await` — the method is async.  `...` (FlowSep) is
//  the pattern→replacement separator; an external token so JS spread {...x} is
//  untouched.  Either side can be a $var (the object itself) or a peeled path.
async replaceTiles(A,w):
    // (1) re-assert — one path → await w.r({solved: 1})
    r %solved
    // receiver before the verb → await A.r({io: "radiostock"})
    A r %io:radiostock
    // multi-key pattern → await w.r({journey: 1, oaims: 1})
    r %journey,oaims

    // (2) two-arg r(pattern, replacement), split by ...  (the dominant usage)
    //  await w.r({buffers: 1}, {ok: 1})
    r %buffers...%ok
    //  await w.r({wear: enid}, {is_nowPlaying: 1, started, re})
    r %wear:$enid...%is_nowPlaying,$started,$re

    // (3) whole-object args — a $var is the pattern|replacement object itself
    //  await w.r(c, fuller)
    r $c...$fuller

    // (4) rm — removal sugar, r(pattern, {}) underneath
    //  await w.rm({stream: 1})
    rm %stream
    //  await w.rm(c)
    rm $c

    // (5) the rest of the two-arg IOness2 family — same match...props shape.
    //  oai is sync (find-or-create-or-mutate, no await); roai is async.
    //   let seat = oai %seat:3...%taken    → let seat = w.oai({seat: 3}, {taken: 1})
    let seat = oai %seat:3...%taken
    //   await w.roai({aim: 1}, {category: cat})
    roai %aim...%category:$cat
    //   A.oai({mo: "main"}, {interval: 1})   — sync, no await
    A oai %mo:main...%interval

    // (6) replace-with-a-block — pattern + a pythonic body (like S) becomes the
    //  async fn() that re-fills the cleared pattern:
    //   await A.replace({journey: 1, oaims: 1}, async () => {
    //       w.i({path: 1}); A.i({oaim: j})
    //   })
    A r %journey,oaims
        i %path
        A i %oaim:$j

// the req family — the heart of the data language.  oai seeds-or-mutates a %req
//  in place (same ref, %mutated flagged on drift); oai + a BLOCK wires that req's
//   do_fn (compiles to doai()).  oai is sync, so — note — this method needs no
//    `async`: the only async thing is each do_fn body, which is its own arrow.
reqTiles(A,w)
    // ── oai: the canonical shape ──────────────────────────────────────────────
    // receiver, a named req with identity keys, props after the "..." that merge
    //  in on every pass — find-or-create-or-mutate.  Sync, no await:
    //   A.oai({req: "step", seq: 2}, {demand: 800})
    A oai %req:step,seq:2...%demand:800
    // re-run with a drifted prop: same identity (req+seq) so it mutates the SAME
    //  req in place, flagging %mutated so a do_fn re-reacts — no new ref:
    //   A.oai({req: "step", seq: 2}, {demand: 1600})
    A oai %req:step,seq:2...%demand:1600

    // named req, no props — pure find-or-create on the name:
    //   let workon = w.oai({req: "workon"})
    let workon = oai %req:workon
    // a maz level + a seed prop after the ...; maz:1 is implied so it never
    //  identifies, but maz:3 here is part of how the stage is seeded:
    //   workon.oai({req: "understanding", maz: 3}, {permanent: 1})
    workon oai %req:understanding,maz:3...%permanent

    // anonymous req — %req with no value is the serialise-me sentinel, handed a
    //  serial (%req:2, 3, …) off the host counter:
    //   w.oai({req: 1})
    oai %req

    // ── oai + a BLOCK: the body becomes the req's do_fn ───────────────────────
    // the same seed, but a BLOCK after it lowers to doai(): seed the %req, then
    //  take the indented body as its one-shot do_fn, handed the req as its implied
    //   arg `req`.  doai is sync and returns a setter (or null once wired), so the
    //    call leads with ";".  The seed reads exactly like a plain oai — identity
    //     path, optional "..." props path, both forwarded to doai():
    //   ;(A.doai({req: "step", seq: 2}, {demand: 800}))?.(async (req) => {
    //       A.i({started: 1}); await req.r({ok: 1})
    //   })
    A oai %req:step,seq:2...%demand:800
        A i %started
        req r %ok

    // a level folded into the identity path instead of a separate props path:
    //   ;(w.doai({req: "waft_roster", eternal: 1}))?.(async (req) => { … })
    oai %req:waft_roster,eternal
        i %roster
        req i %seen

    // nested — a child req wired inside the parent's do_fn.  The implied arg is
    //  always named `req`, so the inner block's `req` shadows the outer one (the
    //   name is per-block; mirrors the runtime's w.doai(desire) → desire.doai(acquire)).
    oai %req:desire
        i %wanting
        req oai %req:acquire,maz:9
            req i %got

// loose peel values + the n%such scalar-child accessor — the two human-friendly
//  tiles.  Bare values may now carry dashes etc; "%" tight between a word and a
//  word-start reads a scalar child (n%such → n.sc.such).
looseScTiles(A,w):
    // (1) loose values — a bare value carrying a non-word char (external PathVal):
    //  w.i({transport: 1, type: "webrtc", reason: "no-direct-route"})
    w i %transport,type:webrtc,reason:no-direct-route
    // word-only stays a string, numeric stays a number — no regression:
    //  w.i({slug: "web-socket", n: 3, f: 3.6, type: "mock"})
    w i %slug:web-socket,n:3,f:3.6,type:mock
    // spaces|commas still need quoting:
    //  w.i({label: 'two words'})
    w i %label:'two words'

    // (2) n%such → n.sc.such — the "%" scalar-child accessor (tight "%" only).
    //  let v = n.sc.such
    let v = n%such.slice(0,12)
    // chains fold left-to-right:  let c = n.sc.a.sc.b
    let c = n%a%b
    // works in a condition too — pythonic if:  if (req.sc.demand) { w.i({go: 1}) }
    if req%demand
        i %go
    // spaced "%" stays modulo, untouched:  let m = idx % len
    let m = idx % len
    // string-safe — a "%" inside quotes is left alone:  let s = "50%off"
    let s = "50%off"

// receiver-amp, the fabricated House alias, and inline IO in a control body — the
//  three seams that used to force raw JS, now tiles.
async ampTiles(A,w):
    // (1) recv&method → recv.method(args): a tight identifier before "&" is the
    //  receiver, the way a leading bareword is for i/o.  pier.do(), req.bump():
    pier&do
    req&bump
    // args ride after the method, like &-calls:  pier.emit('hello', 3)
    pier&emit,'hello',3
    // await flows through untouched:  await pier.settle()
    await pier&settle
    // a bare "&" with no receiver still means this.method(...):
    &severally,A,w,5
    // spaced "&" is left as bitwise-and — tight-vs-spaced, exactly like "%":
    //  let m = a & b
    let m = a & b

    // (2) the House alias is fabricated automatically: if the COMPILED body still
    //  carries a bare `H` (\bH\b) — i.e. raw JS reached for it; the DSL's own `H i …`
    //   receiver lowers to `this` and leaves none — the compiler tucks a `const H = this`
    //    onto this method's opening-brace line (out of the way when debugging the gen),
    //     skipped when H is a param or already declared.  So a raw House call resolves
    //      even inline in a control structure:  if (a > b) H.laterally(A,w,1)
    if (a > b) H.laterally(A,w,1)

    // (3) IO atoms translate inside a control body now (the per-line parser is
    //  threaded into method-body recursion) — both pythonic and parenthesised:
    if a > b
        i %reached:here
    if (a > b) i %reached:also

// the obtain verb family and the $:name capture-out spelling.
obtainTiles(A,w):
    // the full IOness obtain family (not just i|o) compiles — each shares o's
    //  (sc, q) signature: a single-leg recv.verb(sc).  oa is the presence probe:
    //   let s = w.oa({seat: 3})
    let s = oa %seat:3
    // ob | bo | o1 | oa1 | bo1 | boa | boa1 likewise:
    let one = o1 %req:step
    let any = A oa1 %mo:main
    // they translate inside a condition too (a bare o there already reads as oa):
    if (s && !(oa %taken)) i %seat:free

// $:name — the capture-OUT spelling.  "$:" reads "out comes name", the mirror of
//  ":$" (value-IN).  Both name the let; the ":" is sugar, dropped at compile.
captureOutTiles(A,w):
    // value IN on A (the var ang flows in) and row OUT into AB on one line:
    //  let {AB} = this._i_drill_caps(this, [{sc:{A:"Bearing"}, caps:[{as:"AB",…}]}])
    H i A:Bearing$:AB
    // the in|out symmetry, side by side: A:$side is value-in, Pier$:pier is row-out
    o A:$side/w:Peeroleum/Pier$:pier
    // value-out keeps the dot:  .$:name  →  let ang = …?.sc.wither
    A o prefixy,wither.$:ang
    // the older bare spelling stays valid (additive): name$ , name$var , name.$var
    o hut/toot$tval

IMPORT()
    import Peeroleum from "$lib/gen/N/Peeroleum.go"
    import { browserTrustedPubs, prepubOf } from "$lib/p2p/cluster_trust"

RENDER()
    <Peeroleum {H} />
