<script lang="ts">
    import type { Pier, TrustName } from "../Peerily.svelte";

    let {pier}:{pier:Pier} = $props()
    let eer = pier.eer
    
    
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
    // any of these abilities
    let abilities = $derived(eer.features.keys())

    let trust_us_with = $derived(Array.from(pier.trusted?.keys() || []))
    let trusting_them_with = $derived(Array.from(pier.trust?.keys() || []))
    let talk = $derived(
        !trusting_them_with.length && !trust_us_with.length
        ? ""
        : `them to ${trusting_them_with.join("+")},
            we may ${trust_us_with.join("+")}`
    )

    let dropdown_options = $derived(abilities.map(
        (t:TrustName) => trusting_them_with.includes(t)
            ? [{ value: `-${t}`, label: `--${t}`, action: 'revoke' }]
            : [{ value: t, label: t, action: 'grant' }]
    ))

    function handleSelection(event) {
        // debugger
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
    {talk}
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
