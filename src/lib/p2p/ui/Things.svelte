<script lang="ts">
    import { onMount, type Snippet } from 'svelte';
    import Thing from './Thing.svelte'
    import Thingness from './Thingness.svelte'

    interface ThingsProps {
        Ss: any // The collection (DirectoryShares, etc) with .things SvelteMap
        type: string           // e.g. "share", "playlist", "bookmark"
        title?: string        // Display title
        placeholder?: string   // Placeholder for add input
        thing?: Snippet
    }

    let {
        Ss,
        type,
        title = `${type}s`,
        placeholder = `Add ${type}...`,
        thing,
    }: ThingsProps = $props()

    // UI state
    let newItemName = $state('')

    // will probably start all things as well
    onMount(() => {
        Ss.may_start()
    })

    async function addItem() {
        let name = newItemName.trim()
        if (!name) return
        
        try {
            // Use the collection's add method
            await Ss.add_Thing(name)
            newItemName = ''
        } catch (err) {
            console.warn(`Failed to add ${type}:`, err)
        }
    }


    function handleKeydown(event: KeyboardEvent) {
        if (event.key === 'Enter') {
            addItem()
        }
    }
</script>

<div class="things-container">
    <div class="things-header">
        <h3 class="things-title">{title}</h3>
        
        <!-- Use Thingness for collection-level actions -->
        {#if Ss}
            <div class="collection-thingness">
                <Thingness S={Ss} type="collection" showStatus={false} />
            </div>
        {/if}
    </div>
    
    {#if 0}
        <div class="loading">Loading {type}s...</div>
    {:else}
        <div class="things-list">
            {#each Ss.things as [name, S] (name)}
                <Thing
                    {Ss}
                    {S}
                    {name}
                    {type}
                    {thing}
                />
            {/each}
        </div>

        <div class="add-item">
            <input 
                bind:value={newItemName}
                onkeydown={handleKeydown}
                placeholder={placeholder}
                class="add-input"
            />
            <button 
                onclick={addItem}
                disabled={!newItemName.trim()}
                class="add-button"
            >
                Add
            </button>
        </div>
    {/if}
</div>

<style>
    .things-container {
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background: rgba(255, 255, 255, 0.05);
    }

    .things-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.75rem;
    }

    .things-title {
        margin: 0;
        font-size: 1.1rem;
        font-weight: 600;
        color: #333;
        text-transform: capitalize;
    }

    .collection-thingness {
        display: flex;
        align-items: center;
    }

    .loading {
        color: #666;
        font-style: italic;
        padding: 1rem 0;
    }

    .things-list {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .add-item {
        display: flex;
        gap: 0.5rem;
        align-items: center;
    }

    .add-input {
        flex: 1;
        padding: 0.5rem;
        border: 1px solid #ccc;
        border-radius: 4px;
        font-size: 0.9rem;
    }

    .add-input:focus {
        outline: none;
        border-color: #4CAF50;
    }

    .add-button {
        padding: 0.5rem 1rem;
        background: #4CAF50;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
        transition: background 0.2s;
    }

    .add-button:hover:not(:disabled) {
        background: #45a049;
    }

    .add-button:disabled {
        background: #ccc;
        cursor: not-allowed;
    }
</style>