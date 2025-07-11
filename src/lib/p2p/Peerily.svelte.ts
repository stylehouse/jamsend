
import * as ed from '@noble/ed25519';
import type { DataConnection } from 'peerjs';
import Peer from 'peerjs'
import { SvelteMap } from 'svelte/reactivity';

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
export class Peerily {
    stash:TheStash = $state({})
    Id:Idento = new Idento()
    eer:Peer
    peers_by_pub = $state(new SvelteMap())
    constructor(opt={}) {
        Object.assign(this, opt)
    }
    stop() {
        this.eer?.destroy()
    }
    // own pubkey location
    // < by proving you own it
    async listen_pubkey(pub) {
        pub = ''+pub
        if (!pub) throw "!pub"
        this.eer ||= new Peer(pub)
        let pier = this.a_pier(pub)
        console.log(`listen_pubkey(${pub})`)
        this.eer.on('connection', (con) => {
            console.log(`<- connection(${pub})`,con)
            pier.init(con)
        })
    }
    async connect_pubkey(pub) {
        pub = ''+pub
        let con = this.eer.connect(pub)
        if (!con) {
            throw "OHNO"
        }
        let pier = this.a_pier(pub)
        pier.said_hello = false
        con.on('open', () => {
            if (con.peer != pub) debugger
            console.log(`-> connection(${pub})`,con)
            pier.init(con)
            // someone has to try con.send() to get it open
            pier.say_hello()
        });
        console.log(`connect_pubkey(${pub})`)
    }
    a_pier(pub):Pier {
        if (!pub) throw "!pub"
        pub = ''+pub
        let pier = this.peers_by_pub.get(pub)
        if (!pier) {
            pier = new Pier({P:this,pub})
            this.peers_by_pub.set(pub,pier)
        }
        return pier
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
    pub:prepub|null // if we want to find that full pretty_pubkey()
    con:DataConnection


    constructor(opt) {
        super()
        Object.assign(this, opt)
    }
    done_init = false
    init(con) {
        if (this.done_init) return
        this.done_init = true

        this.con = con
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