<script lang="ts">
    // Thang.svelte — one thang particle, with header (name + remove) + slot.
    //
    // Defaults to a minimal card: name on the left, × on the right,
    // children rendered below. Pass-through of t lets callers reach
    // t.sc.stashed / t.sc.* however they like.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { Snippet } from "svelte"

    let { t, on_remove, children }: {
        t: TheC,
        on_remove: () => void,
        children?: Snippet,
    } = $props()
</script>

<article class="thang">
    <header>
        <span class="name">{t.sc.name}</span>
        <button class="rm" title="remove" onclick={on_remove}>×</button>
    </header>
    {#if children}
        <div class="body">{@render children()}</div>
    {/if}
</article>

<style>
    .thang {
        border: 1px solid #e0e0e0;
        border-radius: 6px;
        background: rgba(255, 255, 255, 0.8);
        padding: .4rem .6rem;
        transition: background .15s ease;
    }
    .thang:hover {
        background: rgba(255, 255, 255, 0.95);
        border-color: #ccc;
    }
    header {
        display: flex;
        align-items: center;
        gap: .5rem;
    }
    .name {
        font-weight: 500;
        flex: 1;
        color: #333;
        font-size: .95rem;
    }
    .rm {
        background: transparent;
        border: 0;
        color: #a33;
        cursor: pointer;
        font-size: 1.1rem;
        line-height: 1;
        padding: 0 .25rem;
    }
    .rm:hover { color: #f44; }
    .body { margin-top: .4rem; }
</style>
