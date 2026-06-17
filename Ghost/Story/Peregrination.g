
// LakeNetherland — the Peeroleum test-case wrangler (the outer test layer).
//  Reached only after Peregrination.svelte (the hand-written bootstrap) has
//  compiled + included this dock and Ghost/N/Peeroleum.g, so its sibling methods
//  are live on H. Getting-started: prove we reached compiled code, then seed the
//  wrangler's root desire so the Peeroleum spine has something to pump.
//
// The step choreography fills in under Peeroleum_handover.md headings 2-3:
//   on_step{1}  two sides up under one mock transport (one shared in-process queue)
//   on_step{2}  seed %req:handshake both sides → assert %req:handshake,finished
LakeNetherland(A,w):
    w i %see:'y LakeNetherland — reached from the loader'

    // The wrangler's eternal root desire; its do_fn (the step table) is wired as
    //  the spine lands. Seeding it now proves the .g req language compiles + runs.
    w oai %req:wrangle,eternal

    // < lay the actor topology the spine drives: A:Peerologist/w:Peerologist
    //    (manager — H.req_p2pman seeds the Peerings) plus A:Bearing / A:Nearing
    //     with w:Peeroleum each.  Needs an H-receiver actor-laying form (raw
    //      this.i({A:..}).i({w:..}) for now; a LangTiles `H i` receiver is a seam).
