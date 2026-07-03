<script lang="ts">
    // Plank — the Waft-map's home: hosts DocWaftMap (the cluster map of Waft|Doc attention).  It
    //  flows IN the vertical gap at the bottom of Liesui (the .ls-plank-slot), under all the Waft
    //   columns — not floating over them (the old baseshell cell is the Brink's alone now).
    //    Off-runner is the caller's job (Liesui gates the mount) — the map is editor|author
    //     chrome.  DocWaftMap's own content and layout are the map's concern, separate from
    //      where the Plank sits.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import DocWaftMap from "$lib/O/Funk/DocWaftMap.svelte"

    // search — the universal searchbar's live result set (Liesui threads it through), so the
    //  map can hang the hits off its Doc chips.  Pure UI plumbing; undefined = no search live.
    // onhover — the map's Waft-under-mouse, reported back up (the searchbar's StemHive glows
    //  its member rows).  Same plumbing, opposite direction.
    let { H, w, search, onhover }: {
        H: House, w?: TheC, search?: any, onhover?: (waft?: string) => void } = $props()
</script>

<div class="plank">
    <DocWaftMap {H} {w} {search} {onhover} />
</div>

<style>
    .plank {
        /* in flow inside Liesui's .ls-plank-slot — it just fills the gap and grows with its
           clusters; the Lies panel scrolls, no inner clip. */
        position: relative; width: 100%; min-width: 0;
    }
</style>
