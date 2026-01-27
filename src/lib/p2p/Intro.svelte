<script lang="ts">
    import { onDestroy, onMount } from "svelte";
    import { SvelteSet } from "svelte/reactivity";
	import QrCode from "svelte-qrcode"
    import { Idento, Peerily, PeeringFeature, type StashedPeering,
        Peering as Peering_type
     } from "./Peerily.svelte";
    import ShareButton from "./ui/ShareButton.svelte";
    import { throttle } from "$lib/Y";
    import { PeeringSharing } from "./ftp/Sharing.svelte.ts";
    import GatEnabler from "./ui/GatEnabler.svelte";
    import Trusting from "$lib/FTrusting.svelte";
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
        if (err.type == 'peer-unavailable') {
            let prepub = err.message.match(/^Could not connect to peer (\w+)$/)[1]
            P.Trusting.M.Pier_wont_connect(prepub)
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



    // we'll get Trusting to spur this:
    // onMount(() => P.startup())
    
    P.dosharing = () => {
        sharing()
    }

    
    let link = $state()
    async function sharing() {
        // if (link) return link = null
        // already in the address bar, can become QR code
        link = P.share_url + ",blaggablagga,hitech"
    }
    async function copy_link() {
        await navigator.clipboard.writeText(link);
    }

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
                    <p> Here it is: {link} </p>
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
            <!-- <GatEnabler /> -->
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