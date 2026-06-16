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
    // value capture on a multi-leg o — tval = the %toot value, not the row C
    o hut/toot.$tval
    // single leg, two value captures → tier0-multi takes the caps drill
    A o prefixy,wither.$angle,its.$itsval
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
    //  oai is sync (find-or-create, no await); roai/moai are async.
    //   let seat = oai %seat:3...%taken    → let seat = w.oai({seat: 3}, {taken: 1})
    let seat = oai %seat:3...%taken
    //   await w.roai({aim: 1}, {category: cat})
    roai %aim...%category:$cat
    //   await A.moai({mo: "main"}, {interval: 1})
    A moai %mo:main...%interval

    // (6) replace-with-a-block — pattern + a pythonic body (like S) becomes the
    //  async fn() that re-fills the cleared pattern:
    //   await A.replace({journey: 1, oaims: 1}, async () => {
    //       w.i({path: 1}); A.i({oaim: j})
    //   })
    A r %journey,oaims
        i %path
        A i %oaim:$j

// the req family — the heart of the data language.  moai seeds-or-mutates a
//  %req in place (same ref, %mutated flagged on drift); doai seeds one and wires
//   its do_fn from a block.  Both are async IOness2 verbs, so this method awaits.
async reqTiles(A,w)
    // ── moai: the canonical shape ─────────────────────────────────────────────
    // receiver, a named req with identity keys, props after the "..." that merge
    //  in on every pass — find-or-create-or-mutate:
    //   await A.moai({req: "step", seq: 2}, {demand: 800})
    A moai %req:step,seq:2...%demand:800
    // re-run with a drifted prop: same identity (req+seq) so it mutates the SAME
    //  req in place, flagging %mutated so a do_fn re-reacts — no new ref:
    //   await A.moai({req: "step", seq: 2}, {demand: 1600})
    A moai %req:step,seq:2...%demand:1600

    // named req, no props — pure find-or-create on the name:
    //   let workon = await w.moai({req: "workon"})
    let workon = moai %req:workon
    // a maz level + a seed prop after the ...; maz:1 is implied so it never
    //  identifies, but maz:3 here is part of how the stage is seeded:
    //   await workon.moai({req: "understanding", maz: 3}, {permanent: 1})
    workon moai %req:understanding,maz:3...%permanent

    // anonymous req — %req with no value is the serialise-me sentinel, handed a
    //  serial (%req:2, 3, …) off the host counter:
    //   await w.moai({req: 1})
    moai %req

    // ── doai: same seed, the block becomes the do_fn ──────────────────────────
    // doai seeds the %req then takes the indented body as its one-shot do_fn,
    //  handed the req as its implied arg `req`.  It returns a setter (or null once
    //   wired), so the call leads with ";".  The seed reads exactly like moai —
    //    identity path, optional "..." props path, both forwarded to doai():
    //   ;(await A.doai({req: "step", seq: 2}, {demand: 800}))?.(async (req) => {
    //       A.i({started: 1}); await req.moai({ok: 1})
    //   })
    A doai %req:step,seq:2...%demand:800
        A i %started
        req moai %ok

    // a level folded into the identity path instead of a separate props path:
    //   ;(await w.doai({req: "waft_roster", eternal: 1}))?.(async (req) => { … })
    doai %req:waft_roster,eternal
        i %roster
        req i %seen

    // nested — a child req wired inside the parent's do_fn.  The implied arg is
    //  always named `req`, so the inner block's `req` shadows the outer one (the
    //   name is per-block; mirrors the runtime's w.doai(desire) → desire.doai(acquire)).
    doai %req:desire
        i %wanting
        req doai %req:acquire,maz:9
            req i %got
