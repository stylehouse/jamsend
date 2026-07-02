<script lang="ts">
    // Plank — the Waft-map's home: hosts DocWaftMap (the word-cloud abdomen of Waft|Doc nodes).  It
    //  rests at the foot of Lies inside Liesui's shared BASE-SHELL (the .ls-baseshell-plank cell, filling
    //   the left, with the Brink's %Aim faces in the right cell) — the shell owns the sticky-in-.ls-ui
    //    positioning; this component just fills its cell and caps its own height.  Off-runner is the
    //     caller's job (Liesui gates the mount) — the map is editor|author chrome.  DocWaftMap's own
    //      content and layout are the map's concern, separate from where the Plank sits.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import DocWaftMap from "$lib/O/Funk/DocWaftMap.svelte"

    let { H, w }: { H: House, w?: TheC } = $props()
</script>

<div class="plank">
    <DocWaftMap {H} {w} />
</div>

<style>
    .plank {
        /* positioning owned by Liesui's base-shell (the .ls-baseshell-plank cell) — this just fills it
           and rests at the foot; caps height + scrolls if the cloud gets tall.  (Was a self-pinned
           position:fixed HUD; now flows inside the shared shell beside the Brink.) */
        position: relative; width: 100%; min-width: 0;
        max-height: 60vh; overflow: auto;
        pointer-events: auto;
    }
</style>
