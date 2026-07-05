<script lang="ts">
    // Never reached in the running app — +page.ts throws a 404 before this renders (the root
    //  is intentionally dead; the toplevels live at /BigSoundland and /BigWordland).  It stays
    //   as the route's page component and as the fallback door if that throw is ever removed
    //    (and it satisfies the scaffold unit test's h1 check).
</script>

<h1>404 — not found</h1>
<p>try <a href="/BigSoundland">/BigSoundland</a> (music) or <a href="/BigWordland">/BigWordland</a> (editor)</p>
