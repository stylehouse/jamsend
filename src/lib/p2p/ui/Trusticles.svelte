<script lang=ts>
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
            let i = pier.stashed.trust.findIndex(t => t.to == ability)
            if (i<0) throw "!dis-ability"

        }
        pier.eer.Id.sign(ability)
    }
</script>

Trust:{pier.stashed.trust?.map(t => t.to).join(", ")}

<select>

</select>