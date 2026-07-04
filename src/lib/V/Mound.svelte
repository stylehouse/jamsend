<script lang="ts">
    // Mound — the toplevel of the Piracy-scape (lib/V/), the new Voro+Cyto cutting-edge
    //  UI that takes the / route over from the old p2p/ghost Intro.  Voro gets gathered
    //  in here later; for now it is the merest counter button, so the route swap is
    //  provable on its own before any of the real surface lands.
    let count = $state(0)
</script>

<main class="mound">
    <button class="counter" onclick={() => count++}>
        count is {count}
    </button>
</main>

<style>
    .mound {
        min-height: 100vh;
        display: grid;
        place-items: center;
        background: #06070c;
        color: #e7ecf5;
        font-family: system-ui, sans-serif;
    }
    .counter {
        padding: 0.8em 1.6em;
        font-size: 1.1rem;
        color: inherit;
        background: #141a2b;
        border: 1px solid #2c3c66;
        border-radius: 10px;
        cursor: pointer;
    }
    .counter:hover { background: #1b2440; }
</style>
