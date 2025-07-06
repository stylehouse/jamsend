
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