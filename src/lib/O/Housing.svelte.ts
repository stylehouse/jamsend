import { TheC, type TheUniversal } from "$lib/data/Stuff.svelte";

// Housing is everything through H/A/w/r
//  
abstract class Housing extends TheC {
    // WAS Modus
    //  had .F|PF|S links to the (Pier/)?feature/thing housing it...
    //  < those become lookups? wanting a piece of the rowing|tupling this Housing is embedded in

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link
    up?: Housing

    constructor(opt:TheUniversal) {
        super({sc:{anObj:1}})
        Object.assign(this,opt)

        this.start()
    }
    declare start:Function
}
export class House extends Housing {
    start() {
        $effect(() => {
            if (this.started) {
                
            }
        })
    }
}