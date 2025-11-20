import { TheC } from "./data/Stuff.svelte";

export function throttle(func, interval_ms = 200) {
    let isWaiting = false;
    let nextArgs:null|Array<any> = null;
    function handle(...args) {
        if (isWaiting) {
            nextArgs = args;
            return;
        }
        isWaiting = true;
        func(...args);

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

// Filter array or object by predicate

export function grep(c:Array<any>|Object, s?:any) {
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
export function grop(N, y?) {
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
export function iske(s) {
    return typeof s == 'string' || typeof s == 'number'
}
// Check if itemic, ie C
export function isit(s) {
    return s instanceof TheC
}

// Check if function
export function isfu(s) {
    return typeof s === 'function';
}

// Check if array
export function isar(s) {
    return Array.isArray(s);
}

// s=Object number of keys, or has a d=key
export function hak(s, d?:string) {
    if (!s) return 0;
    return d == null ? Object.keys(s).length : s.hasOwnProperty(d);
}