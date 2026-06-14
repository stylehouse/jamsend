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
