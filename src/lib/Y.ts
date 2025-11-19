
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