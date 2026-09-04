<script lang="ts">
    // Siphon_include — the Story_cli `-I` shim for the Siphon spin-out (Siphon_todo.md).
    //  Ghost/M/Siphon.g + Ghost/Story/Siphonation.g are deliberately NOT registered in
    //   LiesLies.svelte's CREDULER_GHOSTS yet (the spin-out doctrine: new files only; the
    //    registration is a proposed patch at the bottom of Siphon_todo.md).  This shim mounts
    //     their generated .go components so a headless run deposits Siphon_* + Siphonation onto
    //      the same H every other ghost lands on:
    //   BOOK=Siphonation INCLUDE=Siphon_include \
    //     node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts
    //  The gen components only ever call H.eatfunc — the M shim Story_cli.spec.ts passes an
    //   include forwards exactly that — so handing M in as H is the same attach path Machinery
    //    uses for its test-case children.
    //  ALSO mounted: the ghosts the siphon COMPOSES — Ra.go (Ra_press / Ra_rec_find / Ra_recs),
    //   Heist.go (Heist_catalog_land — the one landing door), Heard.go (Heist's census neighbours
    //    live fine without it but Ra's quarter region reads Heard verbs) and Musuation.go
    //     (Musu_float — the family's snap-order float).  A headless Story_cli boot mounts no
    //      Otro, so the Creduler's watched:UIs enrolment never renders and CREDULER_GHOSTS never
    //       deposit — without these mounts the Book's beats throw "this.Ra_rec_find is not a
    //        function" into the Errlog (seen on the first run of this Book, 2026-08-28).
    import SiphonGhost from '$lib/gen/M/Siphon.go'
    import SiphonationGhost from '$lib/gen/Story/Siphonation.go'
    import RaGhost from '$lib/gen/M/Ra.go'
    import HeistGhost from '$lib/gen/M/Heist.go'
    import HeardGhost from '$lib/gen/M/Heard.go'
    import MusuationGhost from '$lib/gen/Story/Musuation.go'
    let { M } = $props()
</script>
<RaGhost H={M} />
<HeistGhost H={M} />
<HeardGhost H={M} />
<MusuationGhost H={M} />
<SiphonGhost H={M} />
<SiphonationGhost H={M} />
