<script lang="ts">
    import { onMount, type Snippet } from 'svelte';
    import Thing from './Thing.svelte'
    import Thingness from './Thingness.svelte'
    import type { DirectoryShares } from '$lib/p2p/ftp/Directory.svelte';
    import type { ThingsIsms } from './Things.svelte.ts';

    // whatever Things/Thing:* we invent before dissolving into pure Stuff
    type TheSs = DirectoryShares | ThingsIsms
    interface ThingsProps {
        Ss: TheSs // The collection (DirectoryShares, etc) with .things SvelteMap
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
            if (name.startsWith('{') && Ss.thawEnteredStashed) {
                // Upsert JSON of S.stashed
                await Ss.thawEnteredStashed(name)
            }
            else {
                // Use the collection's add method
                await Ss.add_Thing({name})
            }
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
        <div>
            <Thingness S={Ss} {type} name={title} showStatus={false} />
        </div>
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
        margin-left: -0.8em;
        background: rgba(255, 255, 255, 0.05);
    }

    .things-header {
        display: flex;
        align-items: center;
        margin-bottom: 0.75rem;
        /* you can't width:100% one of these, it has to be an inner: */
    }
    .things-header div {
        width: 100%;
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
        background: #091409;
        color: lightslategray;
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