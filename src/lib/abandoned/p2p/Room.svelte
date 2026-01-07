<script lang="ts">
    let torrenting = false

    import { joinRoom } from "trystero/mqtt";
    // torrenting = false
    // import { joinRoom } from "trystero/torrent";
    import { Participant } from "./Peer.svelte";
    import { SvelteMap } from "svelte/reactivity";
    let {room:room_id,is_host,stat} = $props()

    let config = {
        appId: "jamsend",
    };
    if (torrenting) {
        // too slow for development
        config.relayUrls = [
            // < disabled because opentracker doesn't do secure websockets?
            // "http://127.0.24.1:6969",
            "wss://tracker.openwebtorrent.com",
            "wss://tracker.files.fm:7073",
            "wss://tracker.webtorrent.dev",
        ]
    }
    else {
        config.relayUrls = [`wss://${window.location.hostname}:9001`]
    }


    let onError = (m,s,b) => {
        console.log("Wonderful",{m,s,b})
    }
    let ostat = stat
    stat = (m,d) => {
        d ? ostat(m+' '+d) : ostat(m)
        console.log("A: "+m,d)
    }
    let participants:Map<peerId, Participant> = $state(new SvelteMap())
    let spam = () => {}
    function joinery() {
        stat("Joining room...")
        const room = joinRoom(config,room_id,onError)
        const [sendMessage, receiveMessage] = room.makeAction('message')

        spam = (m) => sendMessage(m)
        // Handle incoming messages
        receiveMessage((message, peerId) => {
            console.log(`Received from ${peerId}:`, message)
            // Update your UI with the received message
            let par = participants.get(peerId)
            if (!par) return
            par.name = message
        })
        
        // Get notified when peers join/leave
        room.onPeerJoin(peerId => {
            console.log(`Peer joined: ${peerId}`)
            // Update your UI to show the new peer
            participants.set(peerId, new Participant({peerId}))
        })
        
        room.onPeerLeave(peerId => {
            console.log(`Peer left: ${peerId}`)
            participants.delete(peerId)
        })
        stat("Joining room......")
    }
    $effect(() => {
        joinery()
    })

    let mess = "Message"
    async function amuck() {
        spam(mess)
        stat("Geaamuck...")
    }
    
</script>

Peers!
<input bind:value={mess} onchange={amuck} />
<button onclick={amuck}>amuck</button>
<button onclick={joinery}>joinery</button>

<div class="participants">
    <ul>
    {#each [...participants.values()] as par (par.peerId)}
        <li>par {par.peerId}: {par.name}</li>
    {/each}
    </ul>
</div>

<style>
    .participants {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
</style>