<script lang="ts">
    // Ghost.svelte — single mount under Otro.
    // Presents a shim M to each ghost child so their eatfunc() deposits
    // into H.ghosts and triggers H.ghostsHaunt() across H/%H**.
    // H.ghosts ($state null→object) gates subHouse creation in Otro.
    //
    // ── ghost load order ─────────────────────────────────────────────────────
    //
    //   Notable ghosts (the full, ordered mount list is the template at the bottom):
    //   Agency    — w:officing, self-timekeeping, Aw_satisfied, i_unemits_o_Aw
    //   Hovercraft — the req/hover hooks: reqyoncile/e_reqyonciliation, reqonce,
    //               Runstepped, req_diag (the req engine proper is on StuffAware, in Stuff)
    //   Machinery — the test-suite aggregator (all AI): mounts the test-case games
    //               (MachReqy, Mundane, InterestLive, Diffmatication, the Understand*
    //               suite, MachPeerily…) and hosts its own (LangTiles, Lake*, Leaf*,
    //               Stuff*)
    //   Story     — w:Story, snap/toc codec, story_drive, story_save, Run wiring
    //   Cyto      — w:Cyto, cyto_scan, grawave, e_story_cyto_step handshake
    //   Text      — pure text/diff functions: depth_of, char_diff_ops,
    //               compute_diff, squish_context, positional_diff, enDif, deDif
    //   (Matstyle, Interest, Auto, Lang and Lies also mount — see the template, which
    //               carries its own inline notes and is the authority on order.)
    //
    //   All ghosts call M.eatfunc(hash) in onMount.  eatfunc merges hash into
    //   H.ghosts and calls H.ghostsHaunt() which Object.assigns onto every H
    //   instance reachable from root.  Later ghosts can therefore call methods
    //   deposited by earlier ones (e.g. Story calls this._resolve_runstepped
    //   which Hovercraft deposited) — so deposit order (the mount order below) is the
    //   call order.  Mostly free to reorder, except Lang must stay put: moving it up
    //   triggers the elvis-$this weirdness (see the inline note at its mount below).

    import Agency    from "$lib/ghost/Agency.svelte"
    import Machinery from "$lib/O/test/Machinery.svelte"
    import Story     from "$lib/O/Story.svelte"
    import Cyto      from "./Cyto.svelte"
    import Text  from "$lib/O/Text.svelte"
    import Auto from "./Auto.svelte";
    import Matstyle from "./Matstyle.svelte";
    import Lang from "$lib/O/Lang.svelte";
    import Hovercraft from "./Hovercraft.svelte";
    import Lies from "./Lies.svelte";
    import Interest from "./Interest.svelte";
    import Editron from "./Editron.svelte";

    let { H } = $props()   // H = H:Mundo (the real House)

    // shim presented to each ghost instead of H directly.
    // each ghost calls M.eatfunc(hash) on onMount.
    const M = {
        eatfunc(hash: Record<string, Function>) {
            H.eatfunc(hash)
        }
    }
    // so H can be used for lib/gen/ ghosts.
    // M.eatfunc(M)
    // < extract what we will keep from Agency, etc...
</script>
<Agency    {M} />
<Hovercraft {M} />
<!-- below are all AI -->
<Machinery {M} />
<Story     {M} />
<Cyto      {M} />
<Matstyle  {M} />
<!-- %Interest cluster + Lang↔Lies channel reducers (pure logic; no elvis handlers) -->
<Interest  {M} />
<!-- pure text/diff utilities — depth_of, compute_diff, squish_context, enDif, deDif, etc. -->
<Text  {M} />
<!-- what are we working on, and memories drifting away -->
<Auto  {M} />
<!-- < js weirdness: if you move this up below Matstyle, the elvis handlers receive $this as a first argument... -->
<Lang      {M} />
<Lies {M} />
<!-- Editron Book recipe (Run_A_Editron) + per-beat handler; booted via ?B=Editron -->
<Editron {M} />