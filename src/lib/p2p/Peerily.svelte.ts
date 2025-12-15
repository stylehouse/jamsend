
import { KVStore } from '$lib/data/IDB.svelte';
import { objectify } from '$lib/data/Stuff.svelte';
import type { ThingAction } from '$lib/data/Things.svelte';
import type Modus from '$lib/mostly/Modus.svelte';
import * as ed from '@noble/ed25519';
import type { DataConnection, PeerConnectOption } from 'peerjs';
import PeerJS from 'peerjs'
import type { Component } from 'svelte';
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
type TrustName = string
// extra properties may be involved, for consumers of the state of pier.trust|trusted
type TrustedTrust = ToTrust & {qua?:number}
// this is what's signed, is stored without .pub
// server removes .sign and adds .pub to verify the rest as json
type SaidTrusticle = ToTrust & {pub?: Prekey}
type StashedTrusticle = ToTrust | NotTrust
// abilities we have on our peer
type ToTrust = {
    to: TrustName,
    time: number,
    sign: Sighex,
}
// abilities our peer had here, revoked
type NotTrust = {
    not: TrustName,
}
type StashedPier = {
    uninitiated?: boolean,
    pubkey: Pubkey,
    trust: StashedTrusticle[],
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

// the global internet time, UTC in whole seconds
export function now_in_seconds() {
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



//#region Peering (eer)
// per listen address we want (pub)
// < the PeerJS object is funny. for some reason extending it says:
//    TypeError: Class extends value #<Object> is not a constructor or null
//   so we proxy everything
export class Peering {
    P:Peerily
    Id:Idento
    stashed:StashedPeering = $state()
    Peer:PeerJS
    constructor(P,Id,opt) {
        this.P = P
        this.Id = Id
        let prekey = Id+''
        this.Peer = new PeerJS(prekey,opt)
        // and that's it!
        this.P.on_Peering?.(this)
    }


    // multi-user features stack up here (rather than P)
    //  so there's an extra deep partitioning of them
    features = $state(new SvelteMap<TrustName,PeeringFeature>())
    feature(F:PeeringFeature) {
        let k = F.trust_name
        if (this.features.get(k)) throw `dup trust_name=${k}`
        this.features.set(k,F)
        F.eer = this
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
            // no .pubkey yet
            pier.stashed = {}
            this.stashed.Piers ||= []
            this.stashed.Piers.push(pier.stashed)
        }
        else {
            pier.stashed = stashed
            arre(this.stashed.Piers,stashed,pier.stashed)
        }

        return pier
    }
    forget_Pier(pub:Prekey) {
        let before = this.stashed.Piers.length
        this.stashed.Piers = this.stashed.Piers
            .filter(a => !a.pubkey?.startsWith(pub))
        let after = this.stashed.Piers.length
        if (before == after) throw `!forget_Pier`
    }



    // proxy these methods
    on(...args) {
        return this.Peer.on(...args)
    }
    connect(pub,opt:PeerConnectOption={}) {
        // this translates to 'ordered' in lib/dataconnection/DataConnection.ts
        // hasn't proven necessary
        //  and is apparently the default nowadays
        //  though our Pier.con.dataChannel.ordered = false
        opt.reliable = true

        return this.Peer.connect(pub,opt)
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
// the main|single object of our p2p business, over all Peerings
export class Peerily {
    stash:TheStash = $state({})

    on_error:Function|null
    // called for each "host" address we create, before Piers arrive
    on_Peering:Function|null
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

        this.seek_others()

        this.remember_people()
    }
    // if you don't remember yourself
    async listen_to_yourself() {
        if (!this.stash.Peerings?.length) {
            // you're new!
            let Id = new Idento()
            await Id.generateKeys()
            this.a_Peering(Id)
        }
        else {
            // resume Peering at all our Ids
            // < slightly bad security|privacy: all your Ids become online-looking
            this.stash.Peerings.map((a:StashedPeering) => {
                let Id = new Idento()
                Id.thaw(a.keys)
                // they CRUD further into a.**
                this.a_Peering(Id)
            })
        }
    }
    share_url = $state()
    seek_others() {
        // consume the URL they navigated to
        let m = window.location.hash.match(/^#([\w,:]+)$/);
        if (!m) return
        let [hex,...policy] = m[1].split(',')
        if (policy.length) throw `< seek_others() with policy=${policy}`
        
        // the location may be another person's
        let Ud = new Idento()
        Ud.from_hex(hex)
        let prepub = Ud.publicKey && Ud.pretty_pubkey()
        let is_us = this.addresses.has(prepub)
        if (!is_us) {
            this.connect_pubkey(Ud)
        }

        // plant a sharable URL for attracting others to them
        // < this wants navigator.history.push() or some such integration
        window.location.hash = this.address_to_connect_from.Id+''
        this.share_url = window.location.toString()
    }
    // autoconnect everyone you knew! if they're online
    remember_people() {
        let eer = this.address_to_connect_from
        eer.stashed.Piers.map(sp => {
            // put its pubkey into 
            let Ud = new Idento()
            Ud.from_hex(sp.pubkey)
            this.connect_pubkey(Ud)
        })
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
        let stashed = this.stash.Peerings?.find(a => a.keys.pub.startsWith(prepub))
        if (!stashed) {
            eer.stashed = {keys:Id.freeze()}
            this.stash.Peerings ||= []
            this.stash.Peerings.push(eer.stashed)
        }
        else {
            eer.stashed = stashed
            arre(this.stash.Peerings,stashed,eer.stashed)
        }

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


// aka Participant
export class Pier {
    P:Peerily
    stashed:StashedPier = $state()
    forget() {
        this.eer.forget_Pier(this.pub)
    }

    // their pretty and full pubkey
    pub:Prekey|null
    Ud?:Idento
    get name() {
        return this.Ud.toString()
    }

    eer:Peering
    con:DataConnection

    // for ui drawers - see features

    constructor(opt) {
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
            // < is redunant? they're not going to unemit us again without:
            //    con.on open -> init_completo() -> reset_protocol_state()
            // any time the connection might have been mitm attacked
            this.reset_protocol_state()
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
        console.log(`init_completo()(${this.pub})  ${this.inbound ? 'in' : 'out'}  ${this.said_hello ? 'helloed' : ''}`)
        this.handle_data_etc()
        this.done_init = true
        this.reset_protocol_state()
        
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

    // binary emit() puts backpressure here (from PierSharing.sendFile)
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
        return this.con.dataChannel?.bufferedAmount
    }
    get send_ready() {
        return this.con.dataChannel?.readyState == "open"
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
        if (!this.send_ready) {
            console.error(`${this} channel not ready, dropping emit`);
            return
        }

        this.con.send(crypto)
        this.con.send(data)
        buffer && this.con.send(buffer)

        if (typeof data == 'string') data = {data}
        console.log("emit()"+(buffer ? " BUFFER":""),{...data,crypto})
    }

    async emit(type,data={},
        options: {
            priority?: 'high' | 'normal' | 'low',
            quiet: boolean,
        }={}) {
        const { priority = 'high' } = options;

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
                // text comes as ArrayBuffer, binary as Uint8Array !?
                if (buffer.constructor != ArrayBuffer) buffer = buffer.buffer
                crypto.buffer_sign = enhex(await this.eer.Id.sign(buffer))
            }
            
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
    // messages come with crypto first and binary after
    next_unemission = 'crypto'
    next_unemit:{crypto?,data?} = {}
    reset_unemit_state() {
        this.next_unemit = {}
        this.next_unemission = 'crypto'
    }
    // they're always in order but we go async to verify data|buffer
    // we avoid processing the next crypto while verifying the previous data
    unemit_queue = []
    unemit_processing = false
    async unemit(data: any) {
        this.unemit_queue.push(data)
        if (this.unemit_processing) return
        this.unemit_processing = true
        while (this.unemit_queue.length > 0) {
            const currentData = this.unemit_queue.shift()
            try {
                await this.process_single_unemit(currentData)
            } catch (err) {
                console.error(`Error processing unemit:`, err)
                this.reset_unemit_state()
                this.on_error?.(err)
            }
        }
        this.unemit_processing = false
    }
    async process_single_unemit(data:any) {
        // console.log(`unemits ${this.next_unemission}:`,data)
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
            // text comes as ArrayBuffer, binary as Uint8Array !?
            if (data.constructor != ArrayBuffer) data = data.buffer
            let valid = await this.Ud.verify(dehex(crypto.buffer_sign), data)
            if (!valid) throw `invalid buffer_sign`
            this.next_unemit.data.buffer = data
        }
        // we have it all
        let eventual_data = this.next_unemit.data
        this.reset_unemit_state()
        this.handleMessage(eventual_data)
    }
    handleMessage(data) {
        console.log(`unemits ${data.type}:`,data)
        // extra args to the handler for convenient environment grabbing
        let handy = {P:this.P,Pier:this}

        let type:string = data.type
        let handler = this.handlers[data.type]
        if (!handler) {
            // might route to a feature
            if (type.includes('.')) {
                let [trust_name, ...inner_type] = type.split('.')
                data.type = inner_type.join('.')
                // check permit
                let t = this.trust.get(trust_name)
                    || this.trusted.get(trust_name)
                if (!t) throw `unemit !permit to feature: ${trust_name}`

                let PF = this.features.get(trust_name)
                handy.PF = PF
                handler = PF.unemits[data.type]
            }
            if (!handler) {
                return console.warn(`unemit !handler for message type:`, data);
            }
        }
        handler(data,handy);
    }

//#endregion
//#region Pier protocols
    reset_protocol_state() {
        this.said_hello = false

        this.said_trust = false
        this.stated_trust.clear()
        this.trust.clear()
        this.trusted.clear()
    }
    handlers = {
        hello: (data) => {
            console.log("they say hi: ",data)
            this.hear_hello(data)
        },
        trust: (data) => {
            console.log("they say trust: ",data)
            this.hear_trust(data)
        },
        trusted: (data) => {
            console.log("they say trusted: ",data)
            this.hear_trusted(data)
        },
    }

    // hello comes first, gives full pubkey
    said_hello = false
    say_hello() {
        if (this.said_hello) return console.warn("Dont say hello")
        this.emit('hello',{time:now_in_seconds(),publicKey:enhex(this.eer.Id.publicKey)})
        this.said_hello = true
    }
    hear_hello(data) {
        let delta = data.time - now_in_seconds()
        if (Math.abs(delta) > 5) throw `wonky UTC: now-${delta}`

        // they provide their full publicKey
        this.receive_publicKey(data)
        
        // reciprocate or continue
        if (!this.said_hello) {
            this.say_hello()
        }

        // after a hello they are verified!
        //   not mitm using a collided Prekey
        //  we only send trust info to them now
        this.say_trust()
    }
    receive_publicKey(data) {
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
    }



    // trusting them to access the $TrustName service
    //  so that busy servers dont have to hold lots of auth data,
    //   the client holds on to signed trust certs
    //    < which should include the client id
    //  drawbacks:
    //   can only grant trust to someone currently online to receive it
    //   server must retain revoked trust
    said_trust = false
    // what they say we can trust them with
    stated_trust:SvelteMap<TrustName,TrustedTrust> = $state(new SvelteMap())
    // what we actually trust them with, after revocations
    trust:SvelteMap<TrustName,TrustedTrust> = $state(new SvelteMap())
    update_trust() {
        // what they say we can trust them with
        for (let [to,t] of this.stated_trust) {
            if (to != t.to) throw "t!to"
            this.trust.set(to,t)
        }
        // without any revoked
        this.stashed.trust?.forEach(t => {
            if (t.not) {
                this.trust.delete(t.not)
            }
        })
        this.refresh_features()
    }

    // client reminds server what abilities they're allowed
    async say_trust() {
        if (!this.stashed.trust) return
        let trust = this.stashed.trust.filter(t => t.to)
        if (!trust.length) return
        this.said_trust = true

        for (const t of trust) {
            await this.verify_trust(t,true)
        }
        this.emit('trust',{trust})

        // assume that's going to work for now...
        //  they won't send a NotTrust if you're lying
        for (const t of trust) {
            this.trusted.set(t.to,t)
        }
        this.update_trust()
    }
    // server checks and applies those abilities
    async hear_trust({trust}) {
        // < redundant?
        if (!this.said_trust) this.say_trust()
        if (trust.some(t => !t.to)) throw "revoke in trust[]?"
        // verify grants
        // using trust.map() here would not wait for the throw to be effective
        for (const t of trust) {
            await this.verify_trust(t)
        }
        // trust them to do that for this session
        for (const t of trust) {
            this.stated_trust.set(t.to,t)
        }
        this.update_trust()
    }

    get ourId() {
        return this.eer.Id
    }
    get theirId() {
        if (!this.Ud) throw "expected Id by now"
        return this.Ud
    }


    async verify_trust(t,for_us=false) {
        t = {...t}
        // for us, checks pub=us with them.verify
        let believer = for_us ? this.theirId : this.ourId
        let receiver = for_us ? this.ourId : this.theirId
        // it signs the other stuff, if we add .pub on the end
        let sign = t.sign
        delete t.sign
        t.pub = receiver+''
        let valid = await believer.verify(dehex(sign), JSON.stringify(t))
        if (!valid) throw `invalid trust signature to:${t.to}`
        delete t.pub
        t.sign = sign
    }

    // what they trust us with
    //  features we can switch on
    trusted:SvelteMap<TrustName,TrustedTrust> = $state(new SvelteMap())
    async hear_trusted(m:{trust:Array<SaidTrusticle|NotTrust>}) {
        for (const t of m.trust) {
            if ('not' in t) {
                // a revoke
                if (!this.stashed.trust) continue
                let ti = this.stashed.trust.findIndex(st => t.not == st.to)
                if (ti >= 0) this.stashed.trust.splice(ti,1)
                this.trusted.delete(t.not)
            }
            else {
                // a grant
                await this.verify_trust(t,true)
                if (this.stashed.trust) {
                    // replaces any existing $to
                    let ti = this.stashed.trust.findIndex(st => t.to == st.to)
                    if (ti >= 0) this.stashed.trust.splice(ti,1)
                }
                this.stashed.trust ||= []
                this.stashed.trust.push(t)
                // can come with other opinions in t
                this.trusted.set(t.to,t)
            }
        }
        this.refresh_features()
    }
    
    // we trust them
    async grant_trust(to:TrustName,opt={}) {
        // signed data
        let t:SaidTrusticle = {to,time:now_in_seconds(),...opt,pub:this.Ud+''}
        t.sign = enhex(await this.eer.Id.sign(JSON.stringify(t)))
        delete t.pub

        // enable it to save them saying it back to us?
        // < we probably do want to round-trip it, user needs to consent to each feature?
        this.stated_trust.set(to,t)
        if (this.stashed.trust) {
            // un-revoke
            let ti = this.stashed.trust.findIndex(t => to == t.not)
            if (ti >= 0) this.stashed.trust.splice(ti,1)
        }
        this.update_trust()

        // let them know and remember
        this.emit('trusted',{trust:[t]})
        console.log(`grant_trust(${to})`)
    }
    // we un-trust them
    revoke_trust(not:TrustName) {
        // let them know
        this.emit('trusted',{trust:[{not}]})
        // remember it's revoked
        //  since the grant would still work (on the devil's computer)
        this.stashed.trust ||= []
        this.stashed.trust.push({not})
        // disable the in-memory grant
        this.stated_trust.delete(not)
        this.update_trust()
        console.log(`revoke_trust(${not})`)
    }

    //#region Pier features
    features:SvelteMap<TrustName,PierFeature> = $state(new SvelteMap())
    refresh_features() {
        let was = {}
        this.features.forEach((PF,k) => {
            was[k] = {...PF.perm}
        })

        // a PF switches on when either party has trust
        // it must negotiate security despite this
        //  eg can we push music there, or just pull?

        let switch_on = (direction) => {
            return (t:TrustedTrust,k:TrustName) => {
                if (!this.features.get(k)) {
                    // Peerily.F <-> Pier.PF
                    // F must already exist
                    //  thusly we allow a PF to exist and talk to Pier
                    let F = this.eer.features.get(k)
                    let PF = F.spawn_PF({Pier:this})
                    this.features.set(k,PF)
                }
                // and on the 
                let PF = this.features.get(k)
                PF.perm[direction] = t

                let before = was[k]?.[direction]
                if (!before) {
                    direction == 'local' ? 
                        PF.gets_perm_local?.()
                        :
                        PF.gets_perm_remote?.()
                }
            }
        }
        this.trust.forEach(switch_on('local'))
        this.trusted.forEach(switch_on('remote'))

        // Check for lost permissions
        Object.keys(was).forEach(k => {
            let PF = this.features.get(k)
            if (!PF) throw `Feature was removed?`
            // push any trust change
            PF.perm.local = this.trust.get(k) || null
            PF.perm.remote = this.trusted.get(k) || null
            let before = was[k] || {}
            
            // inform PF of losses
            //  so they can eg turn off a stream
            if (before.local && !PF.perm.local) PF.loses_perm_local?.()
            if (before.remote && !PF.perm.remote) PF.loses_perm_remote?.()
        })

        this.features.forEach((PF,k) => {
            console.log("perm: refresh: "+PF.diag_perm())
        })
    }
}



//#endregion
//#region *Feature

// data models...
// < replace this with TheC, etc
export abstract class ActionsAndModus {
    modus?:Modus = $state()
    // eg Shares does a bunch of i_action() on each Share
    actions?: ThingAction[] = $state()
    i_action(act:ThingAction,removal=false) {
        this.actions ||= []
        this.actions = this.actions.filter(a => a.label != act.label)
        if (!removal) this.actions.push(act)
    }
    i_actions(actions) {
        for (let [k,v] of Object.entries(actions)) {
            let c = typeof v == 'function' ? {handler:v} : v
            this.i_action({
                label:k,
                ...c,
            })
        }
    }
}
// one of these, page-globally
//  the main, for-itself UI of the feature as a whole
// < describes how to onramp the feature
export abstract class PeeringFeature extends ActionsAndModus {
    P:Peerily
    // < rename this class PeeringFeature
    eer:Peering
    constructor(opt) {
        super()
        Object.assign(this, opt)
    }
    // creates a single value set|get IndexedDB storager
    // < wants to be stashable for blobs of json?
    spawn_KVStore(table:string,key:string) {
        // dbname is for this feature,
        // store is a KV table, key is your row
        return new KVStore(this,table,key)
    }
    // Database name based on the Idento and feature
    get IDB_DB_name() {
        return `${this.eer.Id}_${this.trust_name}`;
    }

    // defined during F.new()
    IDB_version:number
    IDB_tables:string[]
    // Table names have to be declared somewhere, all at once, when version++
    IDB_Schema(version:number,names:string[]) {
        this.IDB_tables = names
        this.IDB_version = version
    }

    // a
    // gizmos register each Modus anywhere within, can store strings
    gizmos = $state(new SvelteMap())
    gizmo_mem = new SvelteMap()
    stashed_mem(M:Modus|Object,name:string) {
        let key = `PeeringFeature=${objectify(this)}/${name}`
        // we keep a read+writer for each key in the KVStore
        let mem = this.gizmo_mem.get(key)
        if (!mem) {
            mem = this.spawn_KVStore(`gizmo`,key)
            this.gizmo_mem.set(key,mem)
        }
        // an invisible UI:Thingstashed will come for M.stashed
        this.gizmos.set(name,M)
        // and use M.stashed_mem, the KVStore
        M.stashed_mem = mem
    }



        // < have (Peering|Pier)${this.trust_name} objects
        //    passed in svelte.config.ts?

    
    
    // subclass must fill in:

    // trust item this whole feature is under
    trust_name:TrustName
    abstract spawn_PF():PierFeature
    
    UI_component:Component
}

// one of these per Pier with that feature switched on
//  would show UI parts of the feature relevant to the individual Pier
//   eg for PierSharing this would be a small net io dial
//   < click to do a join onto the various tables, eg find that user's downloads
type BidiTrustication = {local:TrustedTrust,remote:TrustedTrust}
export abstract class PierFeature extends ActionsAndModus {
    P:Peerily
    F:PeeringFeature
    // who we're about
    eer:Peering
    Pier:Pier
    // < their perm.local.* (to here) may include arbitrary signed data
    perm:BidiTrustication = $state({})
    constructor(opt) {
        super()
        Object.assign(this, opt)
        this.eer = this.Pier.eer
        if (!this.eer) throw "where eer"
    }

    // as a key-level depth-injecting accessor|specifier, ~~ imem()
    stashed_mem(M:Modus|Object,name:string) {
        let key = `Pier=${this.name}/${name}`
        let mem = this.F.stashed_mem(M,key)
    }
    
    UI_component:Component

    diag_perm() {
        if (!this.perm) return "{}"
        let N = []
        for (let [direction,t] of Object.entries(this.perm)) {
            N.push(`${direction}: ${t ? t.to : '-'}`)
        }
        return N.join(",  ")
    }
    
    // routing messages to this Pier feature on the other end
    abstract unemits:Object
    async emit(type,data={},options={}) {
        // < GOING? handlers can come from w existing, we might not have but want to talk to
        // if (!this.unemits[type]) throw `emit handler unknown to self: ${type}`
        type = `${this.F.trust_name}.${type}`
        await this.Pier.emit(type,data,options)
    }
}


//#endregion



