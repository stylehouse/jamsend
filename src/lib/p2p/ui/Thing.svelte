<script lang="ts">
    import type { Snippet } from 'svelte';
    import Thingness from './Thingness.svelte'
    import type { ThingIsms, ThingsIsms } from '$lib/data/IDBThings.svelte';

    interface ThingProps {
        Ss: ThingsIsms // where is
        S: ThingIsms // the thing
        name: string
        type: string
        thing?: Snippet // how the client of the Things (F's component usually) wants to present each one
    }

    let { Ss, S, name, type, thing }: ThingProps = $props()
    let actions = []
    actions.push({label:'remove',icon:'×',handler: async () => {
        if (confirm(`Remove ${type} "${name}"?`)) {
            await Ss.remove_Thing(name)
        }
    }})

    // always have this in there...
    let compat_mode = $state()
    $effect(() => {
        if (!('showDirectoryPicker' in window)) {
            compat_mode = true
        }
    })
</script>

<div 
    class="thing-item" 
    data-type={type}
    class:started={S.started}
    class:needs-attention={S.no_autostart}
>
    <div class="thing-header">
        <div class="thing-content">
            <div class="thing-name-row">
                <span class="thing-name">{name}</span>
            </div>
            {#if compat_mode}
                <h3>THE COMPAT MODE SPEECH</h3>
                <p>You don't seem to allow Directory writing access. Sorry.</p>
            {/if}
            
            <div class="thing-meta">
                <!-- <span class="thing-type">{type}</span> -->
            </div>
        </div>
        
        <div class="thing-controls">
            <Thingness {S} {type} {actions} />
        </div>
    </div>

    <div class="thing-self">
        {@render thing?.(S)}
    </div>
</div>

<style>
.thing-item {
    display: flex;
    flex-direction: column; /* Changed from default row */
    padding: 0.5rem 0.75rem;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.8);
    transition: all 0.2s ease;
}

.thing-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0.5rem;
}

.thing-self {
    display: block;
    width: 100%;
}

.thing-item:hover {
    background: rgba(255, 255, 255, 0.95);
    border-color: #ccc;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.thing-item.started {
    border-left: 4px solid #4CAF50;
    background: rgba(76, 175, 80, 0.05);
}

.thing-item.needs-attention {
    border-left: 4px solid #FF9800;
    background: rgba(255, 152, 0, 0.05);
}

.thing-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
}

.thing-name-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.thing-name {
    font-weight: 500;
    color: #333;
    font-size: 0.95rem;
}

.status-indicators {
    display: flex;
    align-items: center;
}

.status-badge {
    font-size: 0.8rem;
    font-weight: bold;
}

.status-badge.started {
    color: #4CAF50;
}

.status-badge.stopped {
    color: #666;
}

.status-badge.attention {
    color: #FF9800;
}

.thing-meta {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.thing-type {
    font-size: 0.8rem;
    color: #666;
    background: #f0f0f0;
    padding: 0.2rem 0.4rem;
    border-radius: 3px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.thing-state {
    font-size: 0.75rem;
    color: #888;
    font-style: italic;
}

.thing-controls {
    display: flex;
    gap: 0.3rem;
    align-items: center;
}


/* Type-specific styling */
.thing-item[data-type="share"] {
    border-left: 2px solid #4CAF50;
}

.thing-item[data-type="playlist"] {
    border-left: 2px solid #9C27B0;
}

.thing-item[data-type="bookmark"] {
    border-left: 2px solid #FF9800;
}
</style>