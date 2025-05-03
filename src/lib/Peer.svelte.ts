import * as ed from '@noble/ed25519';

//#region crypto
// Export keys to hexadecimal
const bufferToHex = buffer => [...new Uint8Array(buffer)]
    .map(b => b.toString(16).padStart(2, '0')).join('');

export function exportKeyHex(key) {
    return ed.etc.bytesToHex(key)
}
export function importKeyHex(hex) {
    return ed.etc.hexToBytes(hex)
}

// the crypto features of Idento
export class IdentoCrypto {
    public publicKey = $state()
    public privateKey = $state()

    async generateKeys() {
        const publicKey = ed.utils.randomPrivateKey()
        const privateKey = await ed.getPublicKeyAsync(publicKey)
        this.replaceKeys({ publicKey, privateKey })
    }
    // changes the identity of this Idento
    //  when you become the streamer, etc.
    replaceKeys({ publicKey, privateKey }) {
        Object.assign(this, { publicKey, privateKey })
    }

    async sign(message) {
        if (!this.privateKey) throw "!privateKey"
        const signature = await ed.signAsync(message, this.privateKey)
        return signature
    }

    async verify(signatureHex, message) {
        if (!this.publicKey) throw "!publicKey"
        const signature = signatureHex
        return await ed.verifyAsync(signature,message,this.publicKey)

    }
}

//#region idento
// lifecycle-related helpers
type storableIdento = {pub:string,key:string}
export class Idento extends IdentoCrypto {
    // url bit with a pubkey
    async from_location_hash() {
        let m = window.location.hash.match(/^#(\w+)$/);
        if (!m) return
        this.publicKey = importKeyHex(m[1])
        if (!this.publicKey) {
            console.warn("Malformed public key?",m[1])
        }
    }
    async to_location_hash() {
        window.location.hash = exportKeyHex(this.publicKey)
    }

    async from_json(json) {
        let a:storableIdento = JSON.parse(json)
        this.publicKey = importKeyHex(a.pub)
        this.privateKey = importKeyHex(a.key)
    }

    async to_json() {
        let a:storableIdento = {}
        a.pub = exportKeyHex(this.publicKey)
        a.key = exportKeyHex(this.privateKey)
        return JSON.stringify(a)
    }
}