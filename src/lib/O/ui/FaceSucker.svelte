<script lang="ts">
    import type { Snippet } from "svelte";

    let { content,
          altitude = 33,
          fullscreen = false
        }:{
        content: Snippet<[]>;
        altitude?: number;
        fullscreen: boolean;
    } = $props();
    let z = altitude * 1000
</script>



<div class="hoist" class:fullscreened={fullscreen} style={`z-index:${z};`}>
    <div class="contain" class:fullscreened={fullscreen}>
        {@render content()}
    </div>
</div>
<style>
    div {
        background:black;
    }
    .contain {
        position:relative;
        width: 100%;
        height: 100%;
    }
    .hoist.fullscreened {
        position:fixed;
        top:0;
        left:0;
        width: 100%;
        height: 100%;
    }
    
</style>