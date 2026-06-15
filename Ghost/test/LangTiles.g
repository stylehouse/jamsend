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

    // (5) replace-with-a-block — pattern + a pythonic body (like S) becomes the
    //  async fn() that re-fills the cleared pattern:
    //   await A.replace({journey: 1, oaims: 1}, async () => {
    //       w.i({path: 1}); A.i({oaim: j})
    //   })
    A r %journey,oaims
        i %path
        A i %oaim:$j
