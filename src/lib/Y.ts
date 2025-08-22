
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