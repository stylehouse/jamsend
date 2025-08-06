
import * as ed from '@noble/ed25519';
import type { DataConnection } from 'peerjs';
import PeerJS from 'peerjs'
import { SvelteMap } from 'svelte/reactivity';

const MAX_BUFFER = 64 * 1024; // 64KB
const LOW_BUFFER = MAX_BUFFER * 0.8; // Start sending again at 80%
function Peer_OPTIONS() {
    // to not run your own server:
    // return {}
    // this gets a path intercepted by Caddy in stylehouse/leproxy
    return {host:location.host,port:443,path:"peerjs-server"}
}

function arre(a:Array,gone,neu) {
    const i = a.indexOf(gone)
    if (i < 0) throw "!found"
    a[i] = neu
}

// hex strings, [0-9a-f]
type Sighex = string
type StashedPolicy = {
    to: string,
    sign: Sighex,
}
type StashedPier = {
    uninitiated?: boolean,
    pubkey: Pubkey,
    policies: StashedPolicy[]
}
export type StashedPeering = {
    keys: storableIdento,
    Piers: StashedPier[],
}
type TheStash = {
    Id: storableIdento,
    trust: {},
    Peerings: StashedPeering[],
}

// shortened pubkey, used as your identifier
type Prekey = Sighex
type Pubkey = Sighex
type Prikey = Sighex

function now_in_seconds() {
    return Math.floor(Date.now() / 1000)
}
export function bunch_of_nowish() {
    let t = Math.floor(now_in_seconds() / 5) * 5
    return [t,t-5,t+5,t-10,t+10]

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
        return this
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
    prepub_only = false
    from_hex(pubkey,prikey?) {
        this.prepub_only = pubkey.length == 16
        this.publicKey = dehex(pubkey)
        if (prikey) this.publicKey = dehex(prikey)
        return this
    }

    from_location_hash() {
        let m = window.location.hash.match(/^#(\w+)$/);
        if (!m) return
        let hex = m[1]
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
    pretty_pubkey():Prekey {
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

function Stashedness(this,index) {

}

//#region Peering (eer)
// per listen address we want (pub)
// < the PeerJS object is funny. for some reason extending it says:
//    TypeError: Class extends value #<Object> is not a constructor or null
//   so we proxy everything
class Peering {
    P:Peerily
    Id:Idento
    stashed:StashedPeering = $state()
    Peer:PeerJS
    constructor(P,Id,opt) {
        this.P = P
        this.Id = Id
        let prekey = Id+''
        this.Peer = new PeerJS(prekey,opt)
    }
    // the many remotes
    Piers:SvelteMap<Prekey,Pier> = $state(new SvelteMap())
    a_Pier(pub:Prekey):Pier {
        if (!pub) throw "!pub"
        let pier = this.Piers.get(pub)
        if (!pier) {
            pier = new Pier({P:this.P,Peer:this,pub})
            this.Piers.set(pub,pier)
        }

        // stashable
        // .pubkey as primary key, ignore malformed
        if (this.stashed.Piers?.find(a => !a.pubkey)) {
            this.stashed.Piers = this.stashed.Piers.filter(a => a.pubkey)
        }
        let stashed = this.stashed.Piers?.find(a => a.pubkey?.startsWith(pub))
        if (!stashed) {
            // svelte reactivity: must be given to the object first
            //  or it won't be the same object as ends up in .Piers
            pier.stashed = {uninitiated:true,policies:[]}
            stashed = pier.stashed
            this.stashed.Piers ||= []
            this.stashed.Piers.push(stashed)
            // svelte reactivity: must wake up the array, or something?
            //  or Pier.svelte will not react to its changes
            //   this gotcha seems much stranger than the above
            this.stashed.Piers = this.stashed.Piers
        }
        pier.stashed = stashed
        arre(this.stashed.Piers,stashed,pier.stashed)

        return pier
    }
    // proxy these methods we
    on(...args) {
        return this.Peer.on(...args)
    }
    connect(...args) {
        return this.Peer.connect(...args)
    }
    reconnect(...args) {
        return this.Peer.reconnect(...args)
    }
    destroy(...args) {
        return this.Peer.destroy(...args)
    }
    // the Peer.disconnected is unreliable https://github.com/peers/peerjs/issues/1345
    disconnected = $state(true)
}

//#region Peerily (P)
// the main|single object of our p2p business
export class Peerily {
    stash:TheStash = $state({})
    on_error:Function|null
    save_stash:Function|null
    constructor(opt={}) {
        Object.assign(this, opt)
    }
    destroyed = false
    stop() {
        this.destroyed = true
        console.warn(`P.stop()`)
        for (let [pub, eer] of this.addresses) {
            console.warn(`Peering destroyed: ${pub}`)
            eer.destroy()
        }
        this.addresses.clear()
    }
    // arrive at the webpage! who are we? who do we want?
    async startup() {
        let eer = await this.listen_to_yourself()

        // this.seek_others()

        // the location may be another person's
        let Ud = new Idento()
        Ud.from_location_hash()
        let prepub = Ud.publicKey && Ud.pretty_pubkey()
        let is_us = this.addresses.has(prepub)
        if (!is_us) {
            this.connect_pubkey(Ud)
        }
    }
    // if you don't remember yourself
    async listen_to_yourself() {
        if (!this.stash.Peerings) {
            // you're new!
            let Id = new Idento()
            await Id.generateKeys()
            return this.a_Peering(Id)
        }
        else {
            // resume Peering at all our Ids
            // < slightly bad security|privacy: all your Ids become online-looking
            this.stash.Peerings.map((a:StashedPeering) => {
                let Id = new Idento()
                Id.thaw(a.keys)
                // they CRUD further into a.**
                return this.a_Peering(Id)
            })
        }
    }
    seek_others() {
        // consume the URL they navigated to
        let m = window.location.hash.match(/^#([\w,:]+)$/);
        if (!m) return
        let [hex,...policy] = m[1].split(',')
        // < finish this
    }


    // own pubkey addresses
    //  are one per Peer, so we create them here
    addresses:SvelteMap<Prekey,Peering> = $state(new SvelteMap())
    // there's probably just one of these Peering objects
    // < if there are many, it doesn't matter which does outgoing connect()s?
    address_to_connect_from:Peering|null = null
    // create a new listen address (eer)
    a_Peering(Id:Idento) {
        let prepub = Id+''
        // this'll track this.addresses/$prepub = eer
        let eer = this.addresses.get(prepub)
        if (!eer) {
            eer = this.create_Peering(Id)
            this.addresses.set(prepub,eer)
            this.address_to_connect_from ||= eer
        }

        // stash it with our known selves (keypairs, listen addresses)
        // also, have a list of these...? to keep real objects out of P.stash
        let stashed = this.stash.Peerings?.find(a => a.keys.pub.startsWith(prepub))
        if (!stashed) {
            eer.stashed = {keys:Id.freeze()}
            stashed = eer.stashed
            this.stash.Peerings ||= []
            this.stash.Peerings.push(stashed)
        }
        // < can we update it from eer/Pier?
        eer.stashed = stashed
        arre(this.stash.Peerings,stashed,eer.stashed)


        return eer
    }

    create_Peering(Id:Idento) {
        // these listen to one address (for us) each
        let eer = new Peering(this, Id, Peer_OPTIONS())
        eer.disconnected = true
        eer.on('connection', (con) => {
            console.log(`inbound connection(${con.peer})`)
            let pier = eer.a_Pier(con.peer)
            pier.done_init = false
            pier.init_begins(eer,con,true)
        })
        eer.on('open', () => {
            console.log(`connected (to PeerServer)`)
            eer.disconnected = false
        })
        eer.on('disconnected', () => {
            console.log(`disconnected (from PeerServer)`)
            eer.disconnected = true
            !this.destroyed && eer.reconnect()
        })
        eer.on('error', (err) => {
            this.on_error?.(err)
        })
        return eer
    }

    // to others
    eer_awaitsing = null
    async connect_pubkey(pub,label="") {
        pub = ''+pub
        let eer = this.address_to_connect_from
        if (!eer) throw "!eer"
        if (eer.disconnected) {
            // lots of these pile up sometimes
            // if (this.eer_awaitsing) return
            if (this.destroyed) return console.log(`guess no awaits...`)
            console.log(`connect_pubkey(${pub}) awaits...`)
            this.eer_awaitsing = true
            setTimeout(() => {
                this.eer_awaitsing = false
                this.connect_pubkey(pub)
            }, 410)
            return
        }
        let con = eer.connect(pub)

        if (!con) throw "!con"
        if (con.trivance) throw "con same!"
        con.trivance = 1

        console.log(`connect_pubkey(${pub})\t${label}`)
        let pier = eer.a_Pier(pub)
        pier.init_begins(eer,con)


    }
}


//#endregion
//#region Pier

abstract class PierThings {
    // < maybe?
    // binary emit() puts backpressure here (from Sharing.sendFile)
    send_queue = []
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
    stashed:StashedPier = $state()

    // their pretty and full pubkey
    pub:Prekey|null
    Ud?:Idento 

    eer:Peering
    con:DataConnection


    constructor(opt) {
        super()
        Object.assign(this, opt)

    }
    on_error(err) {
        console.log(`!! error via connection(${this.pub})`)
        this.P.on_error(err)
    }
    disconnected = $state(true)
    was_disconnected = false
    worth_reconnecting = true
    // we are the peer that was first reached out to
    inbound = false
    init_begins(eer,con,inbound=false) {
        if (this.con) {
            // < gets messy (send on a disconnected handle) without con.close here
            if (this.con == con) throw "concon"
            this.con.close()
        }
        if (this.stashed.pubkey) {
            // will insist on this in unemit:hello, slightly better security
            this.Ud = new Idento()
            this.Ud.publicKey = dehex(this.stashed.pubkey)
        }
        this.eer = eer
        this.con = con
        this.inbound = inbound

        con.on('open', () => {
            if (!this.disconnected) return
            this.disconnected = false
            console.log(`-> connection(${this.pub})`)
            // the other con.on handlers, hello procedure, etc:
            this.init_completo(eer,con)
        })
        con.on('close', () => {
            this.disconnected = true
            console.log(`closed connection(${this.pub})`)
            // any time the connection might have been mitm attacked
            this.said_hello = false
            // < if ever staying disconnected, perhaps switching this on:
            //    causes an extra disconnect after an initial hello, though...
            //     like we could wait a while depending on .inbound, then switch on
            const inbound_peer_may_auto_reconnect = 0
            if (this.worth_reconnecting
                && (inbound_peer_may_auto_reconnect || !this.inbound)) {
                // just this isn't enough to make con reopen,
                // this.P.connect_pubkey(this.pub)
                // unless you keep trying it:
                this.auto_reconnect()
            }
        })
        con.on('error', (err) => {
            this.on_error?.(err)
        })

    }
    
    done_init = $state(false)
    init_completo() {
        console.log(`init_completo()(${this.pub})  ${this.inbound}  ${this.said_hello}`)
        this.handle_data_etc()
        this.done_init = true
        this.said_hello = false
        
        // begin crypto introduction
        // also a technicality: someone has to try con.send() to get it open
        if (!this.inbound) {
            this.say_hello()
        }

        return this
    }

    // < friend-online polling
    //  !!!!!!!!!!!!!!!!!!!
    auto_reconnect_time:number|null = null
    auto_reconnect() {
        this.inbound = true
        if (this.auto_reconnect_time) {
            // < there are duplicate con.on('open') handlers somehow
            return
        }
        let get_auto_reconnect_time = () => {
            if (!this.auto_reconnect_time) {
                this.auto_reconnect_time =  100 + Math.random()*100
            }
            this.auto_reconnect_time = this.auto_reconnect_time * 1.21
            return Math.round(Math.min(this.auto_reconnect_time,9000))
        }
        let recur = () => {
            let time = get_auto_reconnect_time()
            if (this.P.destroyed) return console.log(`guess no auto_reconnect...`)
            setTimeout(() => {
                if (!this.disconnected) {
                    // it's over
                    this.auto_reconnect_time = null
                    return
                }
                // try
                this.P.connect_pubkey(this.pub, `retried after ${time}ms`)
                // maybe try again
                recur()
            },get_auto_reconnect_time())
        }
        recur()
    }

//#endregion
//#region Pier emit

    handle_data_etc() {
        // Receive messages
        this.con.on('data', (msg) => {
            this.unemit(msg)
        });
        // backpressure <-> relief
        this.con.dataChannel.bufferedAmountLowThreshold = LOW_BUFFER;
        this.con.dataChannel.onbufferedamountlow = () => {
            this.send_paused = false;
            this.process_emit_queue();
        };
    }
    get send_buffered() {
        return this.con.dataChannel.bufferedAmount
    }
    get send_ready() {
        return this.con.dataChannel.readyState == "open"
    }

    // resume streaming largenesses
    send_paused = false
    send_queue = []
    process_emit_queue() {
        // < etc
        console.log(`process_emit_queue()`)
        while (!this.send_paused && this.send_queue.length > 0) {
            const { crypto,data,buffer, resolve } = this.send_queue.shift()!;
            
            try {
                this.send_stuff({crypto,data,buffer})
                resolve();
                
                if (this.send_buffered > MAX_BUFFER) {
                    this.send_paused = true;
                    break;
                }
            } catch (err) {
                throw 'Error sending queued data'+err;
            }
        }
    }

    send_stuff({crypto,data,buffer}) {
        this.con.send(crypto)
        this.con.send(data)
        buffer && this.con.send(buffer)
    }

    async emit(type,data={},
        options: {
            priority?: 'high' | 'normal' | 'low',
            quiet: boolean,
        }={}) {
        const { priority = 'high' } = options;
        if (!this.send_ready) {
            if (options.quiet) return false
            console.error(`${this} !channel not open, cannot send message type=${type}`);
            return false;
        }

        try {
            // put in type
            data = {type, ...data}
            // may take out buffer
            // < {buffer, ...data} = {type, ...data} !?
            let buffer:Uint8Array|null = data.buffer
            delete data.buffer

            let json = JSON.stringify(data);

            // assures everything we say
            let crypto = {}
            crypto.sign = enhex(await this.eer.Id.sign(json))
            if (buffer) {
                crypto.buffer_sign = enhex(await this.eer.Id.sign(buffer))
            }
            
            console.log("emit()",{...data,crypto})
            // json is already string, crypto isn't
            let stuff = {crypto,data:json,buffer}

            // Queue handling
            if (this.send_buffered > MAX_BUFFER) {
                this.send_paused = true;
                return new Promise((resolve, reject) => {
                    this.send_queue.push({ crypto,data:json,buffer, resolve, reject });
                    
                    // Sort queue by priority if needed
                    if (priority === 'high') {
                        this.send_queue.sort((a, b) => 
                            (a.data['priority'] === 'high' ? -1 : 1));
                    }
                });
            }

            this.send_stuff(stuff)
            return true;
        } catch (err) {
            throw `Failed to send message: `+err
            return false;
        }
    }
    next_unemission = 'crypto'
    next_unemit:{crypto?,data?} = {}
    async unemit(data:any) {
        // console.log(`unemits: `,data)
        if (this.next_unemission == 'crypto') {
            this.next_unemit.crypto = data
            this.next_unemission = 'data'
            return
        }
        else if (this.next_unemission == 'data') {
            if (typeof data != 'string') throw "not string"
            let crypto = this.next_unemit.crypto
            // check it's them
            if (this.Ud) {
                let valid = await this.Ud.verify(dehex(crypto.sign), data)
                if (!valid) throw `invalid signature`
            }
            this.next_unemit.data = JSON.parse(data)

            if (!this.Ud) {
                // only accept hello before we know
                let type = this.next_unemit.data.type
                if (type != 'hello') throw `unauthorised emit:${type}`
            }
            if (crypto.buffer_sign) {
                this.next_unemission = 'buffer'
                return
            }
        }
        else if (this.next_unemission == 'buffer') {
            let crypto = this.next_unemit.crypto
            let valid = await this.Ud.verify(dehex(crypto.buffer_sign), data)
            if (!valid) throw `invalid buffer_sign`
            this.next_unemit.data.buffer = data
        }
        // we have it all
        let eventual_data = this.next_unemit.data
        this.next_unemit = {}
        this.next_unemission = 'crypto'

        // < check permit on data.type
        this.handleMessage(eventual_data)
    }
    handleMessage(data) {
        const handler = this.handlers[data.type]
        if (!handler) {
            return console.warn(`${this} channel !handler for message type:`, data);
        }
        handler(data);
    }

//#endregion
//#region Pier protocols
    said_hello = false
    say_hello() {
        if (this.said_hello) return console.warn("Dont say hello")
        // give them our entire pubkey, enabling new contacts to verify
        this.emit('hello',{time:now_in_seconds(),publicKey:enhex(this.eer.Id.publicKey)})
        this.said_hello = true
    }

    handlers = {
        hello: (data) => {
            console.log("they say hi: ",data)

            let delta = data.time - now_in_seconds()
            if (Math.abs(delta) > 5) throw `wonky UTC: now-${delta}`
            
            // check they are who we want
            let publicKey = data.publicKey
            if (this.Ud) {
                // we already knew them
                let repubkey = enhex(this.Ud.publicKey)
                if (repubkey != publicKey) throw `not them anymore`
            }
            else {
                // we're looking for the full pubkey from an address
                if (!publicKey.startsWith(this.pub)) throw `not them`
                this.Ud = new Idento()
                this.Ud.publicKey = dehex(publicKey)
                this.stashed.pubkey = publicKey
                this.stashed.saw_first ||= now_in_seconds()
                // < hang this off e:ping?
                // this.stashed.saw_last ||= now_in_seconds()
            }

            // reciprocate or continue
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

// 


//#endregion
//#region Trust (us)

class Trust {
    
}

//#endregion



