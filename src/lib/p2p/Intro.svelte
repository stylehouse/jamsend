<script lang="ts">
    import { onDestroy, onMount } from "svelte";
    import { fade } from "svelte/transition";
    import { SvelteSet } from "svelte/reactivity";
    import { Idento, Peerily, PeeringFeature, type StashedPeering,
        Peering as Peering_type
     } from "./Peerily.svelte";
    import ShareButton from "./ui/ShareButton.svelte";
    import { throttle } from "$lib/Y";
    import { PeeringSharing } from "./ftp/Sharing.svelte.ts";
    import GatEnabler from "./ui/GatEnabler.svelte";
    import FTrusting from "$lib/FTrusting.svelte";
    import Peering from "./Peering.svelte";
    import FaceSucker from "./ui/FaceSucker.svelte";

    let spec = `
    more modern A.svelte
     bring in the new users
     cover up and turn off all the crunchy UI until secret buttons are found
      and generally interface with the application proper...
    
    it seems... the only Thingstashed is in Shares!
     and everything else is hung off it
    F:Trust
      it can exist outside of a Peering!
    < supplant P.stashed with M.stashed
       use Things to make tables of:
        Peerings - your idents
        Piers - your contacts
        Trust - your abilities

    < it takes the screen.
      Peerings autovivifies (gives you an identity) or you have one
       then the concept is pitched
      Piers want to hear from you
      Trust lets you
       start the conversation with that
       where an invite can be upgraded to trust proper
       which lasts forever
        < unless the start of its signature is in the revoke database D:
          or they could TTL
       
      
    
    Pier.name
        isn't anywhere
        we kinda could grab a signature or something
         "forge their signature"
        to use as an avatar for them
        as there's a drawer full of them to activate features of
        so the PF should be limited to ... etc
      
    then Trust fades to Sharee** in once it takes over the screen
    
    things to leave half done:
     < do Things of Peering/Pier
    `
    

    let errors = $state(new SvelteSet())
    let peerfail = /^Could not connect to peer (\w+)$/
    let on_error = (err) => {
        if (err.type == 'peer-unavailable' && err.message.match(peerfail)) {
            let prepub = err.message.match(peerfail)[1]
            P.Trusting.M.Pier_wont_connect(prepub)
            return
        }
        errors.add(err)
        console.error(`Error ${err.type}: ${err}`)
    }
    
    let save_stash = () => {
        throw "GONE"
    }
    let on_Peering = (eer:Peering_type) => {
        // < switch features on|off on different Peerings
        //   we'll presume we dont
        //    and the app would get compiled to a subdomain
        //    when it wants different arrangements
        // < whats with this ts problem
        eer.feature(new PeeringSharing({P,eer}))
    }
    let P = new Peerily({on_error,save_stash,on_Peering})

    onDestroy(() => {
        P.stop()
    })
    let title = $state('jamsend')
    onMount(() => {
        document.body.style.setProperty('overflow','hidden')
        title = location.host.split('.')[0]
    })
    let full_title = $derived(title + 
        (!P.PROD ? 
            ' - '+import.meta.env.MODE : ''
        )
    )
    // < get <div transition:fade> working
</script>

<svelte:head>
    <title>{full_title}</title>
</svelte:head>

{#if !P.fade_splash}
    <div transition:fade={{duration:100}}>
    <FaceSucker altitude={44} fullscreen={true}>
        {#snippet content()}
            <center>
                <span id="heading">jamsend</span>
                <img src="favicon.png"/>
            </center>
        {/snippet}
    </FaceSucker>
    </div>
{/if}

<div>
    <pan>
        <ShareButton {P} />
        <span id="heading">Welcome to jamsend.</span>
        <span>
            <GatEnabler />
        </span>
    </pan>

    <!-- <button onclick={tryit}>go</button> -->
    <!-- <button onclick={showstash}>stash</button> -->
    <!-- <button onclick={dropstashedPeerings}>--</button> -->

    <FTrusting {P} /> 

{#if 1}
    <div class=bitsies>
        {#each P.addresses as [pub,eer] (pub)}
            <Peering {pub} {eer} />
        {/each}
    </div>
{/if}
</div>


<style>
    div {
        color: green;
    }
    #heading {
        font-size:4em;
        color:lightgreen;
    }
    center {
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        height:100%;
    }
    center>span {
        position:absolute;
    }
</style>