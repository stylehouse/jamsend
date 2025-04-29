
//#region crypto
const crypto_parameters = { name: "ECDSA", namedCurve: "P-256" }
const crypto_signing_parameters = { name: "ECDSA", hash: {name: "SHA-256"} }
// stringifying

// Export keys to hexadecimal
const bufferToHex = buffer => [...new Uint8Array(buffer)]
    .map(b => b.toString(16).padStart(2, '0')).join('');

export async function exportKeyHex(key, isPrivate = false) {
    const format = isPrivate ? 'pkcs8' : 'spki';
    const exported = await crypto.subtle.exportKey(format, key);
    return bufferToHex(exported);
}

// Import keys from hexadecimal
const hexToBuffer = hex => Uint8Array.from(
    hex.match(/../g).map(byte => parseInt(byte, 16))
).buffer;
async function importPublicKeyHex(hex) {
    return crypto.subtle.importKey(
        'spki',
        hexToBuffer(hex),
        crypto_parameters,
        true,
        ["verify"]
    );
}
export async function importPrivateKeyHex(hex) {
    return crypto.subtle.importKey(
        'pkcs8',
        hexToBuffer(hex),
        crypto_parameters,
        true,
        ["sign"]
    );
}

// the crypto features of Idento
export class IdentoCrypto {
    public publicKey = $state()
    public privateKey = $state()

    async generateKeys() {
        const { publicKey, privateKey } = await crypto.subtle.generateKey(
            crypto_parameters,
            true, // extractable
            ["sign", "verify"]
        );
        this.replaceKeys({ publicKey, privateKey })
    }
    // changes the identity of this Idento
    //  when you become the streamer, etc.
    replaceKeys({ publicKey, privateKey }) {
        Object.assign(this, { publicKey, privateKey })
    }

    async sign(message) {
        const encoded = new TextEncoder().encode(message);
        if (!this.privateKey) throw "!privateKey"
        const signature = await crypto.subtle.sign(
            crypto_signing_parameters,
            this.privateKey,
            encoded
        );
        return bufferToHex(signature);
    }

    async verify(signatureHex, message) {
        const encoded = new TextEncoder().encode(message);
        if (!this.publicKey) throw "!publicKey"
        const signature = hexToBuffer(signatureHex);
        return crypto.subtle.verify(
            crypto_signing_parameters,
            this.publicKey,
            signature,
            encoded
        );
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
        this.publicKey = await importPublicKeyHex(m[1])
        if (!this.publicKey) {
            console.warn("Malformed public key?",m[1])
        }
    }
    async to_location_hash() {
        window.location.hash = await exportKeyHex(this.publicKey)
    }

    async from_json(json) {
        let a:storableIdento = JSON.parse(json)
        this.publicKey = await importPublicKeyHex(a.pub)
        this.privateKey = await importPrivateKeyHex(a.key)
    }

    async to_json() {
        let a:storableIdento = {}
        a.pub = await exportKeyHex(this.publicKey)
        a.key = await exportKeyHex(this.privateKey,true)
        return JSON.stringify(a)
    }
    



    

}