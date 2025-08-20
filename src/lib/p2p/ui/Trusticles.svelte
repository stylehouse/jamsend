<script lang="ts">
    import type { Pier } from "../Peerily.svelte";

    let {pier}:{pier:Pier} = $props()

    // any of these abilities
    //   except for 'forget' which is just a UI overload for deleting this Pier
    let abilities = ['hear','ftp', 'forget']
    function apply(ability) {
        if (ability == 'forget') {
            // not a trust
            return pier.forget()
        }
        if (ability.startsWith('-')) {
            // revoke an ability
            ability = ability.slice(1)
            pier.revoke_trust(ability)
        } else {
            // grant an ability
            pier.grant_trust(ability)
        }
    }
    // Get currently trusted abilities (what we trust them with)
    let trusted_abilities = $state([])
    let dropdown_options = $state([])
    
    $effect(() => {
        trusted_abilities = Array.from(pier.trust?.keys() || [])
    })

    // Get available options for the dropdown
    $effect(() => {
        dropdown_options = abilities.flatMap(ability => {
            if (ability === 'forget') {
                return [{ value: 'forget', label: 'Forget peer', action: 'special' }]
            }
            
            const is_trusted = trusted_abilities.includes(ability)
            
            if (is_trusted) {
                // Show revoke option
                return [{ value: `-${ability}`, label: `--${ability}`, action: 'revoke' }]
            } else {
                // Show grant option  
                return [{ value: ability, label: ability, action: 'grant' }]
            }
        })
    })

    function handleSelection(event) {
        const selectedValue = event.target.value
        if (selectedValue) {
            apply(selectedValue)
            // Reset dropdown to show "Trust" label
            event.target.value = ""
        }
        event.target.blur()
    }
</script>

<div class="trust-container">
    <!-- <span class="trust-status">
        Trust: {trusted_abilities.join(", ") || "none"}
    </span> -->

    <select onchange={handleSelection} class="trust-dropdown">
        <option value="">Trust</option>
        <option disabled>──────────</option>
        {#each dropdown_options as option}
            <option
                value={option.value}
                class="trust-option trust-{option.action}"
            >
                {option.label}
            </option>
        {/each}
    </select>
</div>

<style>
    .trust-dropdown {
        width: 5em;
    }
    .trust-container {
        display: inline-table;
        align-items: center;
        gap: 0.5rem;
    }

    .trust-status {
        font-size: 0.9rem;
        color: #666;
    }

    .trust-option.trust-grant {
        color: #181125;
    }

    .trust-option.trust-revoke {
        color: #cc6600;
        font-style: italic;
    }

    .trust-option.trust-special {
        color: #cc0000;
        font-weight: bold;
    }
</style>
