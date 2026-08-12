<script lang="ts">
    // THE ROOT IS THE MUSIC SCAPE (the owner 2026-08-12: *"we also want to svelte route / ->
    //  BigSoundland.svelte now, it's our toplevel handler. where people go"*).  Until today `/`
    //   threw a 404 and the scape lived only at `/BigSoundland`; it now mounts the SAME component,
    //    so the two paths are one page reached two ways.
    //  MOUNTED, NOT REDIRECTED, and that is the whole difference that matters.  An invite is a URL
    //   with the token in its query (`?I=…` / `?Iz=…`) and a redirect rewrites the address bar the
    //    person is looking at mid-arrival — the one moment the URL is doing work.  Mounting leaves
    //     `https://host/?I=…` exactly as it was scanned, and every existing `/BigSoundland?I=…`
    //      link keeps working untouched, because that route is still there.
    //  THE BOT COST IS REAL AND IS PAID DELIBERATELY.  The old `+page.ts` existed to say so: bots
    //   hammer `/`, and each hit now SSRs the scape instead of erroring out cheaply.  Nothing
    //    expensive happens server-side (no Ghost, no audio, no WebRTC — those are all client), but
    //     it is ~280KB of HTML per crawl.  `static/robots.txt` is the answer to that, and it is the
    //      right one: the app is a private p2p thing between friends, so there is nothing here a
    //       search index should ever hold.  If crawlers that ignore robots.txt become the problem,
    //        the next lever is `export const ssr = false` on this route ONLY — the scape needs no
    //         server render at all — and NOT re-closing the door people are told to walk through.
    import BigSoundland from "$lib/V/BigSoundland.svelte";
</script>

<BigSoundland />
