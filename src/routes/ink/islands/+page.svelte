<script lang="ts">
    // /ink/islands — the InkSurprise population demo.
    //  Shows the "ink = continuous island of shared style/idea" concept:
    //  particles that resolve alike (same mainkey) share one ink-region;
    //  anomalies (extra sc keys, undef values, undropped finished reqs,
    //  .c foam) break the island with surprise-proportional darkness.
    import InkSurprise from '$lib/O/ui/InkSurprise.svelte'
</script>

<svelte:head>
    <title>InkSurprise — ink islands</title>
</svelte:head>

<InkSurprise />
