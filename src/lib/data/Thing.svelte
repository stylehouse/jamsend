<script lang="ts">
    import type { Snippet } from 'svelte';
    import Thingness from './Thingness.svelte'
    import type { ThingIsms, ThingsIsms } from '$lib/data/Things.svelte';

    interface ThingProps {
        Ss: ThingsIsms // where is
        S: ThingIsms // the thing
        name: string
        type: string
        thing?: Snippet // how the client of the Things (F's component usually) wants to present each one
    }

    let { Ss, S, name, type, thing }: ThingProps = $props()
    let actions = []
    actions.push({label:'remove',icon:'×',class:'stop',handler: async () => {
        if (confirm(`Remove ${type} "${name}"?`)) {
            await Ss.remove_Thing(name)
        }
    }})
</script>

<div 
    class="thing-item" 
    data-type={type}
    class:started={S.started}
    class:needs-attention={S.no_autostart}
>
    <div class="thing-header">
        
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
    margin-left: -0.8em;
}

.thing-self {
    display: block;
    /* width: 100%; */
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