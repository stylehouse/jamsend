<script lang="ts">
    import { onDestroy, onMount } from "svelte";
    import { SvelteSet } from "svelte/reactivity";
	import QrCode from "svelte-qrcode"
    import { Idento, Peerily, PeeringFeature, type StashedPeering,
        Peering as Peering_type
     } from "./Peerily.svelte";
    import ShareButton from "./ui/ShareButton.svelte";
    import { throttle } from "$lib/Y";
    import { PeeringSharing } from "./ftp/Sharing.svelte";
    import GatEnabler from "./ui/GatEnabler.svelte";
    import Trusting from "$lib/Trusting.svelte";
    import Peering from "./Peering.svelte";

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
    let on_error = (err) => {
        errors.add(err)
        console.error(`Error ${err.type}: ${err}`)
    }

    // top level storage
    //  Peering|Pier.stashed.* come out of here
    //  features each have their own IndexedDB
    //  < more hidden-in-the-dom storage as well
    //    for people that want to save the app as a document
    function load_stash() {
        console.log(`loading Vstash`)
        P.stash = JSON.parse(localStorage.Vstash)
    }
    // < GOING what was P.stash.Peering[0] = eer.stashed
    //    is now provided by OurPeering.stashed, see UI:Thingstashed
    let save_stash = throttle(() => {
        console.log(`saving Vstash`)
        localStorage.Vstash = JSON.stringify(P.stash)
    },200)


    let on_Peering = (eer:Peering_type) => {
        // < switch features on|off on different Peerings
        //   we'll presume we dont
        //    and the app would get compiled to a subdomain
        //    when it wants different arrangements
        eer.feature(new PeeringSharing({P,eer}))
    }
    let P = new Peerily({on_error,save_stash,on_Peering})

    onDestroy(() => {
        P.stop()
    })



    // we'll get Trusting to spur this:
    // onMount(() => P.startup())
    


    
    let link = $state()
    async function sharing() {
        if (link) return link = null
        // already in the address bar, can become QR code
        link = P.share_url + ",blaggablagga,hitech"
    }
    async function copy_link() {
        await navigator.clipboard.writeText(link);
    }


    $effect(() => {
        0 &&
        setTimeout(() => {
            [455,2455,5455].map(ms => setTimeout(() => tryit(), ms))
        },1)
    })
    $inspect(P.stash)


</script>

<div>
    <pan>
        <span onclick={sharing}>
            <ShareButton />
            {#if link}
                <qrthing>
                    <p> <button onclick={copy_link}>Copy Link</button> </p>
                    <pqr> <QrCode value={link} /> </pqr>
                </qrthing>
            {/if}
        </span>
        
        <span>
            <label for="onramptype" >onramp</label>
            <select id="onramptype">
                <option>figaro</option>
                <option>figaro</option>
            </select>
        </span>
        <span>
            <GatEnabler />
        </span>
    </pan>

    <!-- <button onclick={tryit}>go</button> -->
    <!-- <button onclick={showstash}>stash</button> -->
    <!-- <button onclick={dropstashedPeerings}>--</button> -->

    <Trusting {P} /> 

{#if 1}
    <div class=bitsies>
        {#each P.addresses as [pub,eer] (pub)}
            <Peering {pub} {eer} />
        {/each}
    </div>
{/if}

</div>

<style>
    qrthing {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
        backdrop-filter: blur(4px);
    }
    pqr {
        background: white;
        padding-left: 26px;
        padding-top: 30px;
    }
    div {
        color: green;
    }
</style>