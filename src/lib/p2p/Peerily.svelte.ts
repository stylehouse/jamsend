
import * as ed from '@noble/ed25519';
import type { DataConnection } from 'peerjs';
import PeerJS from 'peerjs'
import { SvelteMap } from 'svelte/reactivity';

function Peer_OPTIONS() {
    // to not run your own server:
    // return {}
    return {host:location.host,port:443,path:"peerjs-server"}
}

type TheStash = {
    Id: storableIdento,
    trust: {},
}
type prepub = string
export function bunch_of_nowish() {
    let seconds = Math.floor(Date.now() / 1000)
    let t = Math.floor(seconds / 5) * 5
    return [t,t-5,t+5,t-10,t+10]

}
//#endregion
//#region Peerily
// < This PeerJS object is funny. for some reason extending it says:
//    TypeError: Class extends value #<Object> is not a constructor or null
//   so we proxy everything
class Peer {
    P:Peerily
    pub:prepub
    Peer:PeerJS
    constructor(P,pub:prepub,opt) {
        this.P = P
        this.pub = pub
        this.Peer = new PeerJS(pub,opt)
    }
    // the many remotes
    Piers:SvelteMap<prepub,Pier> = $state(new SvelteMap())
    a_pier(pub):Pier {
        if (!pub) throw "!pub"
        pub = ''+pub
        let pier = this.Piers.get(pub)
        if (!pier) {
            pier = new Pier({P:this.P,Peer:this,pub})
            this.Piers.set(pub,pier)
        }
        return pier
    }
    // proxy these methods we
    on(...args) {
        return this.Peer.on(...args)
    }
    connect(...args) {
        return this.Peer.connect(...args)
    }
    destroy(...args) {
        return this.Peer.destroy(...args)
    }
}
export class Peerily {
    stash:TheStash = $state({})
    Id:Idento = new Idento()
    eer:Peer
    on_error:Function|null
    constructor(opt={}) {
        Object.assign(this, opt)
    }
    stop() {
        console.warn(`P.stop()`)
        for (let [pub, eer] of this.addresses) {
            console.warn(`Peer destroyed: ${pub}`)
            eer.destroy()
        }
        this.addresses.clear()
    }
    // if you don't remember yourself
    // < identity per ?id=..., which we namespace into which stash...
    async generate_keys() {
        await this.Id.generateKeys()
        this.stash.Id = this.Id.freeze()
    }
    // becomes the url to bring your people to
    link = $state()
    async startup() {
        // yourself
        if (this.stash.Id) {
            this.Id.thaw(this.stash.Id)
        }
        else {
            // become someone
            await this.generate_keys()
        }
        this.listen_pubkey(this.Id)

        // the location may be another persons
        let Ud = new Idento()
        Ud.from_location_hash()
        // if it's not us
        if (Ud.publicKey && Ud.pretty_pubkey() != this.Id.pretty_pubkey()) {
            this.connect_pubkey(Ud)
        }

        // location becomes us, so we can share it easily
        this.link = this.Id.to_location_hash()
    }


    // own a pubkey address!
    //  are one per Peer, so we create them here
    // < by proving you own it
    addresses:SvelteMap<prepub,Peer> = $state(new SvelteMap())
    // there's probably just one of these Peer objects
    // < if there are many, it doesn't matter which does outgoing connect()s?
    address_to_connect_from:Peer|null = null
    async listen_pubkey(pub) {
        pub = ''+pub
        if (!pub) throw "!pub"
        let eer = this.addresses.get(pub)
        if (!eer) {
            eer = this.setupPeer(pub)
            this.addresses.set(pub,eer)
            this.address_to_connect_from ||= eer
        }
        console.log(`listen_pubkey(${pub})`)
    }
    setupPeer(pub:prepub) {
        // these listen to one address (for us) each
        let eer = new Peer(this, pub, Peer_OPTIONS())
        eer.disconnected = true
        eer.on('connection', (con) => {
            let pier = eer.a_pier(con.peer)
            console.log(`inbound connection(${con.peer})`,con)
            pier.init(eer,con)
        })
        eer.on('open', () => {
            console.log(`connected (to PeerServer)`)
            eer.disconnected = false

        })
        eer.on('disconnected', () => {
            console.log(`disconnected (from PeerServer)`)

        })
        eer.on('error', (err) => {
            this.on_error?.(err)
        })
        return eer
    }
    async pending_PeerServer() {

    }


    // to others
    async connect_pubkey(pub) {
        pub = ''+pub
        let eer = this.address_to_connect_from
        if (!eer) throw "!eer"
        if (eer.disconnected) {
            console.log(`eer.connect awaits...`)
            setTimeout(() => this.connect_pubkey(pub), 210)
            return
        }
        console.log(`eer.connect)`)
        let con = eer.connect(pub)
        console.log(`eer.connect)!`,con)

        if (!con) throw "!con"
        if (con.trivance) throw "con same!"
        con.trivance = 1

        let pier = eer.a_pier(pub)
        // pier.said_hello = false
        console.log(`connect_pubkey(${pub})`)

        con.on('open', () => {
            if (con.peer != pub) debugger
            console.log(`-> connection(${pub})`,con)
            pier.init(eer,con)
            // someone has to try con.send() to get it open
            pier.say_hello()
        })
        con.on('error', (err) => {
            console.log(`!! connection(${pub})`,con)
            this.on_error?.(err)
        })
    }
}

//#endregion
//#region crypto
// Export keys to hexadecimal
export const enhex = ed.etc.bytesToHex
export const dehex = ed.etc.hexToBytes
// ensure Uint8Array (Bytes)
function enu8(message) {
    return message instanceof Uint8Array ? 
        message : new TextEncoder().encode(message)
}

// the crypto features of Idento
export class IdentoCrypto {
    public publicKey:ed.Bytes = $state()
    public privateKey:ed.Bytes = $state()

    async generateKeys() {
        const privateKey = ed.utils.randomPrivateKey()
        const publicKey = await ed.getPublicKeyAsync(privateKey)

        this.replaceKeys({ publicKey, privateKey })
    }
    // changes the identity of this Idento
    //  when you become the streamer, etc.
    replaceKeys({ publicKey, privateKey }) {
        Object.assign(this, { publicKey, privateKey })
    }

    async sign(message) {
        if (!this.privateKey) throw "!privateKey"
        const signature = await ed.signAsync(enu8(message),this.privateKey)
        return signature
    }

    async verify(signature, message) {
        if (!this.publicKey) throw "!publicKey"
        let verified = await ed.verifyAsync(signature,enu8(message),this.publicKey)
        return verified
    }

    get pub():ed.Hex {
        if (!this.publicKey) return ''
        return enhex(this.publicKey)
    }
}


//#endregion
//#region idento
// lifecycle-related helpers
export type storableIdento = {pub:string,key:string}
export class Idento extends IdentoCrypto {
    // url bit with a pubkey
    from_location_hash() {
        let m = window.location.hash.match(/^#(\w+)$/);
        if (!m) return
        let hex = m[1]
        if (hex.length == 16) this.advert = true
        this.publicKey = dehex(hex)
        if (!this.publicKey) {
            console.warn("Malformed public key?",hex)
        }
    }
    to_location_hash() {
        window.location.hash = this.pretty_pubkey()
        return window.location.toString()
    }
    // when we only have the pretty part of the pubkey
    //  we can't verify signatures but can find out the longer pubkey
    advert = false
    pretty_pubkey():prepub {
        return enhex(this.publicKey).slice(0,16)
    }
    toString() {
        return this.pretty_pubkey()
    }

    thaw(a:storableIdento) {
        this.publicKey = dehex(a.pub)
        if (a.key) this.privateKey = dehex(a.key)
    }
    freeze() {
        let a:storableIdento = {}
        a.pub = enhex(this.publicKey)
        if (this.privateKey) a.key = enhex(this.privateKey)
        return a
    }
}
//#endregion
//#region Pier

abstract class PierThings {
    // < maybe?
    // binary emit() puts backpressure here (from Sharing.sendFile)
    _sendQueue = []
    // ui drawers
    // for ftp
    sharing:Sharing|undefined = $state()
    sharing_requested = $state(false)
    async start_sharing() {
        this.sharing = new Sharing({par:this})
        await this.sharing.start()
    }
    async stop_sharing() {
        await this.sharing.stop()
        this.sharing = null
    }
}


// aka Participant
export class Pier extends PierThings {
    P:Peerily
    Peer:Peer
    pub:prepub|null // if we want to find that full pretty_pubkey()
    eer:Peer
    con:DataConnection


    constructor(opt) {
        super()
        Object.assign(this, opt)
    }
    done_init = $state(false)
    init(eer,con) {
        if (this.done_init) return
        this.done_init = true

        this.eer = eer
        this.con = con
        let pub = con.peer
        let pier = eer.Piers.get(pub)
        // Receive messages
        this.con.on('data', (msg) => {
            this.unemit(msg)
        });
        return this
    }
    said_hello = false
    say_hello() {
        if (this.said_hello) return true
        // give them our entire pubkey
        // < sign a recent timestamp
        this.emit('hello',{publicKey:enhex(this.P.Id.publicKey)})
        this.said_hello = true
    }

    emit(type,data={},options={}) {
        // put in type
        // < binary mode
        data = {type, ...data}
        // become only about data going somewhere
        // < sign from here (another JSON.stringify() at each end?)
        if (!this.pub) throw "!Pier.pub"
        let msg = {
            to: this.pub,
            from: this.P.Id.pretty_pubkey(),
            sig: "yes",
            data
        }
        this.con.send(msg)
    }
    unemit(msg) {
        let data = msg.data
        // < check permit
        this.handleMessage(data,msg)
    }
    handleMessage(data) {
        const handler = this.handlers[data.type]
        if (!handler) {
            return console.warn(`${this} channel !handler for message type:`, data);
        }
        handler(data);
    }

    handlers = {
        hello: (data) => {
            console.log("they say hi: ",data)
            if (!this.said_hello) {
                this.say_hello()
            }
            else {
                this.emit('story',{yadda:3})
            }
        },
        story: (data) => {
            console.log("they say story: ",data)
            data.yadda++ < 9
                && this.emit('story',{yadda:data.yadda})
        },
    }
}
//#endregion