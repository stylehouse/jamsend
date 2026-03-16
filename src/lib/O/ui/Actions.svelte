<script lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"

    let { N }: { N: TheC } = $props()

    let actions = $derived(N)

    function fire(a: TheC) {
        try {
            a.sc.fn?.()
        } catch (err) {
            console.warn(`Action "${a.sc.label}" failed:`, err)
        }
    }
</script>

{#each actions as a}
    <button
        onclick={() => fire(a)}
        class="btn btn-{a.sc.cls ?? 'default'}"
        title={a.sc.label}
        disabled={a.sc.disabled ?? false}
    >
        {a.sc.icon ?? a.sc.label}
    </button>
{/each}

<style>
.btn {
    padding: 0.3rem 0.6rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    line-height: 0.8;
    font-size: 0.8rem;
    transition: background 0.2s ease;
    background: #2196F3;
    color: white;
}
.btn:hover { background: #1976D2; }
.btn:disabled { opacity: 0.4; cursor: default; }

.btn-start  { background: #4CAF50; }
.btn-start:hover  { background: #45a049; }

.btn-stop   { background: #f44336; }
.btn-stop:hover   { background: #d32f2f; }

.btn-save   { background: #FF9800; }
.btn-save:hover   { background: #F57C00; }

.btn-big {
    padding: 0.4rem 0.8rem;
    font-weight: 600;
    font-size: 0.85em;
    background: #FF5722;
}
.btn-big:hover { background: #E64A19; transform: scale(1.05); }

.btn-remove {
    background: #f44336;
    font-weight: bold;
    width: 24px;
    height: 24px;
    padding: 0;
}
.btn-remove:hover { background: #d32f2f; transform: scale(1.1); }
</style>