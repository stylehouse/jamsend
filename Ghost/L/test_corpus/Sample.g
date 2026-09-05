// Sample.g — a frozen fixture for AtlasStaple (Atlantation.g).  Never edit this file for any reason
//  other than the Book's own design changing: its dige, line count, def/call counts are locked into
//  wormhole/Story/AtlasStaple's recorded fixture.  Three defs, one call (via Sample_alpha), one
//  region — small and legible enough to eyeball in a Book snap diff.

//#region a tiny region, on purpose — exercises the region kind too
Sample_alpha(w):
    this.Sample_beta(w)
    return w

Sample_beta(w):
    return w.o({ Doc: 1 })
//#endregion

Sample_gamma():
    return 1
