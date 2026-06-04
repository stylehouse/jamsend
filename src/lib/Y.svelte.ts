import { TheC } from "./data/Stuff.svelte";
import * as ed from '@noble/ed25519';





//#region crypto
export async function dig(data: string): Promise<string> {
    return (await sha256(data)).slice(0, 16)
}
export async function sha256(data: string): Promise<string> {
    const encoder = new TextEncoder();
    const dataBuffer = encoder.encode(data);
    const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    return hashHex;
}

// hex strings, [0-9a-f]
export type Sighex = string
export type Prepub = string
export type Pubkey = string
export type Prikey = string
export type storableIdento = {pub:string,key:string}
export type PrePub = string
// Export bytes to hexadecimal
export const enhex = ed.etc.bytesToHex
export const dehex = ed.etc.hexToBytes
// ensure Uint8Array (bytes)
function enu8(message) {
    return message instanceof Uint8Array ? 
        message : new TextEncoder().encode(message)
}


// the crypto features of Idento
export class IdentoCrypto {
    public publicKey:ed.Bytes = $state()
    public privateKey:ed.Bytes = $state()

    async generateKeys(seed?: string | Uint8Array) {
        let privateKey: Uint8Array;

        if (seed) {
            // Deterministic path for testing
            if (typeof seed === 'string') {
                // Hash the string to ensure a consistent 32-byte array
                const encoder = new TextEncoder();
                const dataBuffer = encoder.encode(seed);
                const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
                privateKey = new Uint8Array(hashBuffer);
            } else {
                privateKey = seed; // If passing raw bytes directly
            }
        } else {
            privateKey = ed.utils.randomPrivateKey()
        }
        const publicKey = await ed.getPublicKeyAsync(privateKey)

        this.replaceKeys({ publicKey, privateKey })
        return this
    }
    // changes the identity of this Idento
    //  when you become the streamer, etc.
    replaceKeys({ publicKey, privateKey }) {
        Object.assign(this, { publicKey, privateKey })
    }

    async sig(message) {
        return enhex(await this.sign(message))
    }
    async ver(sign,message) {
        return await this.verify(dehex(sign),message)
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
export class Idento extends IdentoCrypto {
    // url bit with a pubkey
    prepub_only = false
    from_hex(pubkey) {
        this.prepub_only = pubkey.length == 16
        this.publicKey = dehex(pubkey)
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
    pretty_pubkey():Prepub {
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


//#region misc








export const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer etc



export function exactly(sc) {
    return map(v=>String(v),tex({}, sc))
}

export function indent(d) {
    if (d == 0) throw "d!>0"
    if (isar(d)) d = d.length
    // 1:'',2:'  ',3:'    '..., ie you could give d=T.c.path
    return new Array(1*d).join('  ')
}

// slow down calls to a function
export function throttle(func, interval_ms = 200, q:{notnow?:Boolean}={}) {
    let isWaiting = false;
    let nextArgs:null|Array<any> = null;
    function handle(...args) {
        if (isWaiting) {
            nextArgs = args;
            return;
        }
        isWaiting = true;
        if (!q.notnow) func(...args);
        else nextArgs = args


        setTimeout(() => {
            isWaiting = false;
            
            // If there's a queued call, execute it
            if (nextArgs !== null) {
                handle(...nextArgs);
                nextArgs = null
            }
            else {
            }
        }, interval_ms);
    };
    return handle
}



// add an enclosing context onto an error
//  used by catch(err) {...} everywhere
// you should throw them as it doesn't collect them.
// < pass data in third arg? or 2nd if not Error|string?
export function erring(label: string, err?: Error | string): Error {
    if (!err) {
        // same as just: throw "the label"
        return new Error(label)
    }
    // Create base error from string if needed
    if (typeof err === 'string') {
        err = new Error(err);
    }

    // Build indented label stack
    const indent = ' '.repeat(2);
    let fullMessage = label;
    let currentErr = err;
    let depth = 1;
    while (currentErr) {
        fullMessage += '\n' + indent.repeat(depth)
            + (currentErr.local_msg || currentErr.msg
                || currentErr.message || currentErr);
        currentErr = currentErr.cause;
        depth++;
    }
    // Create new error with the original as its cause
    const wrappedError = new Error(fullMessage, { cause: err });
    wrappedError.msg = fullMessage;
    wrappedError.local_msg = label
    
    // V8-specific stack cleanup
    //  makes it go from the caller's perspective
    // < otherwise you get a stack full of "erring()" ?
    //    we should massage the stack in ErrorLog.svelte
    if (0 && Error.captureStackTrace) {
        Error.captureStackTrace(wrappedError, erring);
    }
    
    return wrappedError;
}

// warning: from here down is AI translated from stylehouse / NutGravy, Pictures, etc

// Parser that modifies string and captures matches
export class Parserify {
    s: string;           // current string being parsed
    m: RegExpMatchArray | null = null;  // match array
    it?: string;         // matched text (m[0])
    whole?: string;      // alias for it
    1?: string;          // capture group 1
    2?: string;          // capture group 2
    3?: string;          // capture group 3

    constructor(s: string) {
        this.s = s;
    }

    // Pattern match and replace
    p(r: RegExp | string, ...placements: (string | number)[]): boolean {
        const regex = typeof r === 'string' ? new RegExp(r) : r;
        this.m = this.s.match(regex) || [];
        
        // Clear previous captures
        delete this[1];
        delete this[2];
        delete this[3];
        delete this.it;
        delete this.whole;
        
        if (!this.m.length) return false;
        
        // Store captures
        this.it = this.whole = this.m[0];
        if (this.m[1] !== undefined) this[1] = this.m[1];
        if (this.m[2] !== undefined) this[2] = this.m[2];
        if (this.m[3] !== undefined) this[3] = this.m[3];
        
        // Build replacement string
        let place = "";
        for (const p of placements) {
            if (typeof p === 'number') {
                // Reference capture group (from 1)
                place += this.m[p] || '';
            } else {
                place += p;
            }
        }
        
        // Replace in string
        this.s = this.s.replace(regex, place);
        return true;
    }

    // Apply pattern repeatedly with callback
    a(regex: RegExp | string, callback: (...args: any[]) => void, opts?: { noloop?: boolean }) {
        opts = opts || {};
        let times = 30;
        
        while (this.p(regex)) {
            callback(...(this.m || []));
            
            if (!times--) throw new Error("looping");
            if (opts.noloop) return;
        }
    }
}


export function reverse(s:Array<any>) {
    return s.slice().reverse()
}
// some of the smallest structures
// reversibly|diffily, create transform theory
// phenom comes in waves
// waves have a skin
// skins relate posture
// even ...arguments become the values, like perl's {@kvs}
export function hashkv() {
    let args = [...arguments];
    
    if (args.length == 1) {
        const first = args[0];
        if (!isar(first)) {
            // hashkv('it') -> {it:1}
            args.push(1);
        } else {
            // hashkv([[nc&sip,n]+]) -> {'0 1 2':n}
            //  !N.length -> {}
            const array = isar(first[0]);
            // hashkv(['it','es']) -> {it:1,es:1}
            args = [];
            for (let i in first) {
                const n = first[i];
                args.push(array ? n[0] : n);
                args.push(array ? n[1] : 1);
            }
        }
    }
    
    let c = null;
    while (args.length) {
        const k = args.shift();
        if (c && args.length < 1) {
            throw new Error("odd hashkv");
        }
        const v = args.shift();
        c = c || {};
        if (!iske(k)) debugger;
        c[k] = v;
    }
    return c || {};
}

// map, [] or {}, waves of y(v,k)
export function map(...args) {
    const N = args.pop();
    const array = isar(N);
    const waves = [N];
    
    // map(N) ~~ N.slice()
    if (!hak(args)) {
        if (!isar(N)) throw "N!ar"
        args.push(s => s);
    }
    
    args.reverse().forEach(y => {
        const N = waves.slice(-1)[0];
        const neu = array ? [] : {};
        waves.push(neu);
        
        for (let i in N) {
            const n = N[i];
            if (array) i = i * 1;
            neu[i] = y(n, i);
        }
    });
    
    return waves.slice(-1)[0];
}
export function armap(...args) {
    let s = map(...args)
    return isar(s) ? s : Object.values(s)
}

// Filter array or object by predicate
// < param type this so s of type Pier[] iterates v of type Pier
export function grep(c:Array<any>|Object, s?:any):Array<any>|Object {
    // no function greps for true
    // see also nex(), for not-null
    if (arguments.length == 1) {
        s = c;
        c = { y: v => v };
    } else if (isfu(c)) {
        // function
        c = { y: c };
    } else if (isit(c)) {
        // item: usually C to look for in /$n
        c = { is: c };
    } else if (isar(c)) {
        c = { in: c };
    }
    
    if (hak(c, 'is')) {
        c.y = v => v == c.is;
    }
    if (hak(c, 'in')) {
        c.y = v => c.in.includes(v);
    }
    if (isfu(s)) {
        throw "iterating? it's grep(y,N)";
    }
    
    const array = isar(s);
    const o = array ? [] : {};
    
    for (let k in s) {
        const v = s[k];
        if (!c.y(v, k, o, s)) continue;
        if (array) {
            o.push(v);
        } else {
            o[k] = v;
        }
    }
    return o;
}

// false if empty, like &za
export function grap(c, s?:any) {
    const N = grep(c, s);
    return hak(N) && N;
};

// removing .filter, y=[n+]|&n{1}|$n
export function grop(y?,N) {
    const out = [];
    
    // expets is|includes
    if (isar(y)) {
        const Z = y;
        y = n => Z.includes(n);
    } else if (hak(y, 'is')) {
        const v = y.is;
        y = n => n == v;
    } else if (!isfu(y)) {
        const v = y;
        y = n => n == v;
    }
    
    const array = !N || isar(N);
    for (let i in N) {
        const n = N[i];
        if (array) i = i * 1;
        if (y(n, i)) {
            out.unshift(i);
        }
    }
    
    return array 
        ? out.map(i => N.splice(i, 1)[0]).reverse()
        : tax({}, N, out);
};

// can be a key (object property name)
export function iske(s): boolean {
    return typeof s == 'string' || typeof s == 'number'
}
// Check if itemic, ie C
export function isit(s: any): boolean {
    return isC(s)
}
export function isC(s: any): boolean {
    return s instanceof TheC
}
// function
export function isfu(s: any): boolean {
    return typeof s === 'function';
}
// array
export function isar(s: any): boolean {
    return Array.isArray(s);
}
// hash
export function isha(s: any): boolean {
    return s && typeof s === 'object' && !isar(s);
}
// string
export function isst(s: any): boolean {
    return typeof s === 'string';
}

//#region data transforms


// Null-fatal peel
export function peli(l: any): Record<string, any> {
    if (!(isst(l) || isar(l) || isha(l))) {
        throw erring("!peli", String(l));
    }
    return peel(l);
}

// Extend object s with properties from c
export function ex(s: Record<string, any>, c: Record<string, any>, ...rest: Record<string, any>[]): Record<string, any> {
    if (!s || typeof s !== 'object') throw erring("ex!s");
    if (!c || typeof c !== 'object') throw erring("ex!c");
    
    for (const k in c) {
        s[k] = c[k];
    }
    
    // Handle additional arguments
    if (rest.length) {
        rest.forEach(extra => ex(s, extra));
    }
    
    return s;
}

// < too hard|weird: mex() - ex with array merge

// Selective extend
export function sex(s: Record<string, any>, c: Record<string, any>, q?: any, e?: number): Record<string, any> {
    let y: ((k: string) => boolean) | null = null;
    
    if (e === 1) {
        y = k => c[k] && true;
    }
    
    q = peli(q);
    
    for (const k in q) {
        if (hak(c, k) && (!y || y(k))) {
            s[k] = c[k];
        }
    }
    
    return s;
}


// Selectively not extending
//  eg nex(c,s,c) extends what isnt in c.* yet
export function nex(s: Record<string, any>, c: Record<string, any>, avoid_c?: any): Record<string, any> {
    avoid_c = peli(avoid_c);
    
    for (const k in c) {
        if (hak(avoid_c, k)) continue;
        s[k] = c[k];
    }
    
    return s;
}

// Text/keyish only
export function tex(s: Record<string, any>, c: Record<string, any>): Record<string, any> {
    for (const k in c) {
        const v = c[k];
        if (iske(v)) {
            s[k] = c[k];
        }
    }
    
    return s;
}
// Defined only (not null/undefined)
export function dex(s: Record<string, any>, c: Record<string, any>): Record<string, any> {
    for (const k in c) {
        const v = c[k];
        if (v != null) {
            s[k] = c[k];
        }
    }
    
    return s;
}
// Selective ex, taking out (unless k:0)
// Consumes arguments from c
export function tax(s: Record<string, any>, c: Record<string, any>, take: any): Record<string, any> {
    if (!c) return s;
    if (!isha(s)) throw erring("tax s?", String(s));
    if (!isha(c)) throw erring("tax c?", String(c));
    
    take = peli(take);
    
    for (const k in take) {
        const remove = take[k];
        if (!hak(c, k)) continue;
        
        if (remove) {
            s[k] = c[k];
            delete c[k];
        } else {
            s[k] = c[k];
        }
    }
    
    return s;
}


// 有 — does s own key d?  omit d → key count
export function hak(s: Record<string,any>, d?: string): number | boolean {
    if (!s) return 0
    return d == null
        ? Object.keys(s).length
        : Object.prototype.hasOwnProperty.call(s, d)
}

// 差 — keys whose values differ between s and d (symmetric)
export function hakd(s: Record<string,any>, d: Record<string,any>): string[] {
    const dif: Record<string,1> = {}
    for (const [k,v] of Object.entries(s)) if (!hak(d,k) || d[k] !== v) dif[k] = 1
    for (const [k,v] of Object.entries(d)) if (!hak(s,k) || s[k] !== v) dif[k] = 1
    return Object.keys(dif)
}

// 等 — identical?  c restricts to those keys only
export function heq(
    s: Record<string,any>,
    d: Record<string,any>,
    c?: Record<string,any>
): boolean {
    if (c) {
        const ks = Object.keys(c)
        s = Object.fromEntries(ks.filter(k => hak(s,k)).map(k => [k, s[k]]))
        d = Object.fromEntries(ks.filter(k => hak(d,k)).map(k => [k, d[k]]))
    }
    return !hakd(s, d).length
}

//#region peel
// Hash from 'k:str,le=3,obvious' comma-separated.
//
// ── defaults ──────────────────────────────────────────────────────────────
//   sep      ','   field separator
//   hie      ':'   string-value separator  (colon → always string on decode)
//   hie_num  '='   number-value separator  (equals → always number on decode)
//              defaults to hie when hie is non-default, so custom-separator
//              callers see zero behaviour change and can still type-scheme freely
//
// ── codec rules (default hie=':' path) ───────────────────────────────────
//   k        bare key    → number 1   (flag)
//   k=N      equals      → number N   (equations have numbers)
//   k:v      colon       → string v   (writing has colons — never coerced)
//
// The colon form is always a string, even when v looks numeric ("3", "0", "1").
// This is the one rule that makes number|string unambiguous across round-trips.
//
// < hie_num is transitional; once all snaps are migrated it can be removed
//   along with the depeel modern opt, leaving the clean codec permanent.
//
export function peel(s: any, d?: { sep?: string; hie?: string; hie_num?: string }): Record<string, any> {
    d = d || {};
    const hie_was_default = !('hie' in d)
    d.sep     ??= ','
    d.hie     ??= ':'
    d.hie_num ??= hie_was_default ? '=' : d.hie
    if (s == null || s === '') return {};
 
    if (isar(s)) {
        // < is just hashkv(s)?
        return hashkv(s.map(k => [k, 1]));
    }
 
    // Clone supplied hash
    if (isha(s)) {
        return ex({}, s);
    }
 
    if (isst(s)) {
        const c: Record<string, any> = {};
        const parts = s.split(d.sep);
 
        for (const part of parts) {
            // find the first hie or hie_num character to split on;
            //  whichever comes first wins — ties go to hie (string)
            const hi      = part.indexOf(d.hie)
            const ni      = d.hie_num !== d.hie ? part.indexOf(d.hie_num) : -1
            const use_hie = hi >= 0 && (ni < 0 || hi <= ni)
            const use_num = ni >= 0 && !use_hie
 
            let k
            if (use_hie) {
                // k:v — always a string, never coerced
                k = part.slice(0, hi)
                if (!k) continue
                c[k] = part.slice(hi + 1)
            } else if (use_num) {
                // k=N — always a number
                k = part.slice(0, ni)
                if (!k) continue
                const raw = part.slice(ni + 1)
                const n = Number(raw)
                c[k] = Number.isNaN(n) ? raw : n
            } else {
                // bare key — number 1
                k = part.trim()
                if (!k) continue
                c[k] = 1
            }
             if ('unmodernised') {
                // Convert numeric strings to numbers
                if (c[k] && typeof c[k] === 'string' && c[k].match(/^-?\d+\.?\d*$/)) {
                    c[k] = parseFloat(c[k]);
                }
            }
        }
        return c;
    }
 
    throw erring("not peely", String(s));
}

// Hash into 'k:v,k2=N,k3' string.
//
// ── codec rules (modern=true, the default on hie=':' path) ──────────────
//   number 1  → bare key     (flag shorthand)
//   number N  → k=N          (equals — unambiguously numeric on decode)
//   string v  → k:v          (colon — always string on decode)
//
// ── legacy behaviour (modern=false) ──────────────────────────────────────
//   all non-1 values → k:v; value===1 → bare key
//   callers with custom hie get modern=false automatically (hie_num==hie,
//   no distinction) so they keep their existing fuzzy-decode behaviour.
//
// < modern: flip to always-on once all existing snaps are migrated
//
export function depeel(s: Record<string, any>, d?: { sort?: boolean; sep?: string; hie?: string; hie_num?: string; modern?: boolean }): string {
    d = d || {};
    const hie_was_default = !('hie' in d)
    d.sep     ??= ','
    d.hie     ??= ':'
    d.hie_num ??= hie_was_default ? '=' : d.hie
    d.sort    ??= false
    // d.modern  ??= hie_was_default  // < uncomment once all snaps are migrated
    let ks = Object.keys(s);
    if (d.sort) ks = ks.sort()
    const hs: string[] = [];
 
    for (const k of ks) {
        const v = s[k]
        if (d.modern && typeof v === 'number') {
            // bare key for the canonical flag value 1; k=N for everything else
            hs.push(v === 1 ? k : k + d.hie_num + v)
        } else {
            // legacy: bare only for value===1; everything else gets hie
            if (v === 1) hs.push(k)
            else hs.push(k + d.hie + v)
        }
    }
 
    return hs.join(d.sep);
}
